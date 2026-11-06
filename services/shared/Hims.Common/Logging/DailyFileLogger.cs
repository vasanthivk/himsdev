using System.Text;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Hims.Common.Logging;

/// <summary>
/// Writes every log entry to &lt;directory&gt;/&lt;dd-MM-yyyy&gt;.log (e.g. logs/patient-engagement/30-09-2026.log), and Error/Critical
/// entries also to &lt;dd-MM-yyyy&gt;-error.log. Both switch to a new file when the local date changes.
/// Filtered like any other provider: Logging:LogLevel, or Logging:File:LogLevel.
/// </summary>
[ProviderAlias("File")]
public sealed class DailyFileLoggerProvider : ILoggerProvider
{
    private readonly DailyFile _all;
    private readonly DailyFile _errors;

    public DailyFileLoggerProvider(string directory)
    {
        directory = Path.GetFullPath(directory);
        Directory.CreateDirectory(directory);
        _all = new DailyFile(directory, "");
        _errors = new DailyFile(directory, "-error");
    }

    public ILogger CreateLogger(string categoryName) => new DailyFileLogger(this, categoryName);

    internal void Write(LogLevel level, string line)
    {
        _all.Write(line);
        if (level >= LogLevel.Error) _errors.Write(line);
    }

    public void Dispose()
    {
        _all.Dispose();
        _errors.Dispose();
    }

    /// <summary>One dated file: &lt;directory&gt;/&lt;dd-MM-yyyy&gt;&lt;suffix&gt;.log, reopened when the date changes.</summary>
    private sealed class DailyFile : IDisposable
    {
        private readonly string _directory;
        private readonly string _suffix;
        private readonly object _lock = new();
        private DateOnly _currentDate;
        private StreamWriter? _writer;

        public DailyFile(string directory, string suffix)
        {
            _directory = directory;
            _suffix = suffix;
        }

        public void Write(string line)
        {
            lock (_lock)
            {
                var today = DateOnly.FromDateTime(DateTime.Now);
                if (_writer is null || today != _currentDate)
                {
                    _writer?.Dispose();
                    _currentDate = today;
                    var path = Path.Combine(_directory, today.ToString("dd-MM-yyyy") + _suffix + ".log");
                    // FileShare.ReadWrite so the file can be tailed / opened while the service is running
                    var stream = new FileStream(path, FileMode.Append, FileAccess.Write, FileShare.ReadWrite);
                    _writer = new StreamWriter(stream, new UTF8Encoding(false)) { AutoFlush = true };
                }
                _writer.WriteLine(line);
            }
        }

        public void Dispose()
        {
            lock (_lock)
            {
                _writer?.Dispose();
                _writer = null;
            }
        }
    }
}

internal sealed class DailyFileLogger : ILogger
{
    private readonly DailyFileLoggerProvider _provider;
    private readonly string _category;

    public DailyFileLogger(DailyFileLoggerProvider provider, string category)
    {
        _provider = provider;
        _category = category;
    }

    public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;

    public bool IsEnabled(LogLevel logLevel) => logLevel != LogLevel.None;

    public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter)
    {
        if (!IsEnabled(logLevel)) return;
        var message = formatter(state, exception);
        if (string.IsNullOrEmpty(message) && exception is null) return;

        var line = $"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff} {LevelName(logLevel),-8} {_category}: {message}";
        if (exception is not null) line += Environment.NewLine + exception;
        _provider.Write(logLevel, line);
    }

    private static string LevelName(LogLevel level) => level switch
    {
        LogLevel.Trace => "TRACE",
        LogLevel.Debug => "DEBUG",
        LogLevel.Information => "INFO",
        LogLevel.Warning => "WARNING",
        LogLevel.Error => "ERROR",
        LogLevel.Critical => "CRITICAL",
        _ => level.ToString().ToUpperInvariant(),
    };
}

public static class DailyFileLoggingExtensions
{
    /// <summary>
    /// Adds daily file logging (console logging stays on) and logs unhandled exceptions to the same file.
    /// Directory: Logging:File:Directory if set, else &lt;repo&gt;/logs/&lt;serviceName&gt; (resolved from the project folder).
    /// Call it first in Program.cs so startup failures are captured too.
    /// </summary>
    public static WebApplicationBuilder AddHimsFileLogging(this WebApplicationBuilder builder, string serviceName)
    {
        var directory = builder.Configuration["Logging:File:Directory"];
        if (string.IsNullOrWhiteSpace(directory))
            directory = Path.Combine(builder.Environment.ContentRootPath, "..", "..", "logs", serviceName);
        else if (!Path.IsPathRooted(directory))
            directory = Path.Combine(builder.Environment.ContentRootPath, directory);

        var provider = new DailyFileLoggerProvider(directory);
        builder.Logging.AddProvider(provider);

        // Crashes that never reach an ILogger: unhandled exceptions on any thread, and faulted tasks nobody awaited.
        var crashLog = provider.CreateLogger("Unhandled");
        AppDomain.CurrentDomain.UnhandledException += (_, e) =>
            crashLog.LogCritical(e.ExceptionObject as Exception, "Unhandled exception (terminating: {IsTerminating})", e.IsTerminating);
        TaskScheduler.UnobservedTaskException += (_, e) =>
            crashLog.LogError(e.Exception, "Unobserved task exception");

        return builder;
    }
}
