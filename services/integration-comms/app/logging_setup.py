"""Logging: console + one file per day in LOG_DIR named dd-MM-yyyy.log (e.g. logs/integration/30-09-2026.log),
plus dd-MM-yyyy-error.log holding only ERROR and CRITICAL entries."""
import logging
import os
import sys
import threading
from datetime import date

LOG_FORMAT = "%(asctime)s %(levelname)-7s %(name)s: %(message)s"


class DailyFileHandler(logging.FileHandler):
    """Writes to <log_dir>/<dd-MM-yyyy><suffix>.log and switches to a new file when the local date changes."""

    def __init__(self, log_dir: str, suffix: str = "", encoding: str = "utf-8"):
        self.log_dir = os.path.abspath(log_dir)
        self.suffix = suffix
        os.makedirs(self.log_dir, exist_ok=True)
        self.current_date = date.today()
        super().__init__(self._path_for(self.current_date), mode="a", encoding=encoding, delay=True)

    def _path_for(self, d: date) -> str:
        return os.path.join(self.log_dir, d.strftime("%d-%m-%Y") + self.suffix + ".log")

    def emit(self, record: logging.LogRecord) -> None:
        today = date.today()
        if today != self.current_date:   # emit() runs under the handler lock, so the switch is thread-safe
            self.close()
            self.current_date = today
            self.baseFilename = self._path_for(today)
        super().emit(record)


def configure_logging(log_dir: str, level: int = logging.INFO) -> None:
    logging.basicConfig(level=level, format=LOG_FORMAT)
    file_handler = DailyFileHandler(log_dir)
    file_handler.setFormatter(logging.Formatter(LOG_FORMAT))
    error_handler = DailyFileHandler(log_dir, suffix="-error")   # file is only created on the first error of the day (delay=True)
    error_handler.setLevel(logging.ERROR)
    error_handler.setFormatter(logging.Formatter(LOG_FORMAT))
    for name in ("", "uvicorn", "uvicorn.access"):
        logger = logging.getLogger(name)
        # under uvicorn its loggers don't propagate to the root logger, so they need the file handlers too;
        # if they do propagate (e.g. imported without uvicorn), the root's handlers already get them - no duplicates
        if name and logger.propagate:
            continue
        logger.addHandler(file_handler)
        logger.addHandler(error_handler)
    _install_crash_hooks()


def _install_crash_hooks() -> None:
    """Send uncaught exceptions (main thread and worker threads) to the log instead of bare stderr."""
    crash_log = logging.getLogger("hub.crash")

    def main_hook(exc_type, exc_value, exc_tb):
        if issubclass(exc_type, KeyboardInterrupt):   # Ctrl+C is not a crash
            sys.__excepthook__(exc_type, exc_value, exc_tb)
            return
        crash_log.critical("Uncaught exception", exc_info=(exc_type, exc_value, exc_tb))

    def thread_hook(args: threading.ExceptHookArgs) -> None:
        if issubclass(args.exc_type, SystemExit):   # same as the default hook: a thread calling sys.exit() is not a crash
            return
        name = args.thread.name if args.thread else "unknown"
        crash_log.critical("Uncaught exception in thread %s", name, exc_info=(args.exc_type, args.exc_value, args.exc_traceback))

    sys.excepthook = main_hook
    threading.excepthook = thread_hook
