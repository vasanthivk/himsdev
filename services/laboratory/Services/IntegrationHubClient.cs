using System.Net.Http.Json;
using Hims.Common.Events;

namespace Hims.Laboratory.Services;

public record ProvisionInterfaceRequest(int AnalyzerId, string AnalyzerCode, string AnalyzerName, string Protocol,
    string? SendingApplicationId, string? HostAddress, int? Port, bool IsBidirectional,
    // Open Integration Engine connection for this device; null = the hub's own setting
    string? EngineUrl = null, string? EngineUser = null, string? EnginePassword = null, bool? EngineVerifyTls = null,
    string? EngineTemplateChannel = null, int? EngineFirstListenPort = null, string? HubPublicUrl = null, string? EngineChannelUrl = null);

public record ProvisionInterfaceResponse(string ChannelId, string RoutingKey, string Status, string? Message);

/// <summary>Calls the (Python) Integration Hub to wire a device into the Open Integration Engine.</summary>
public interface IIntegrationHubClient
{
    Task<ProvisionInterfaceResponse> ProvisionAsync(ProvisionInterfaceRequest request, CancellationToken ct);
}

public class IntegrationHubClient : IIntegrationHubClient
{
    private readonly HttpClient _http;
    public IntegrationHubClient(HttpClient http) => _http = http;

    public async Task<ProvisionInterfaceResponse> ProvisionAsync(ProvisionInterfaceRequest request, CancellationToken ct)
    {
        using var response = await _http.PostAsJsonAsync("api/interfaces", request, EventJson.Options, ct);
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadFromJsonAsync<ProvisionInterfaceResponse>(EventJson.Options, ct);
        return body ?? throw new InvalidOperationException("Integration Hub returned an empty response");
    }
}
