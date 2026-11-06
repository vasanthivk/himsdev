using System.Text.Json;
using System.Text.Json.Serialization;

namespace Hims.Common.Events;

/// <summary>One JSON convention for every event and API in HIMS: camelCase property names, enums as strings.</summary>
public static class EventJson
{
    public static readonly JsonSerializerOptions Options = Create();

    private static JsonSerializerOptions Create()
    {
        var o = new JsonSerializerOptions(JsonSerializerDefaults.Web);
        o.Converters.Add(new JsonStringEnumConverter());
        return o;
    }

    public static string Serialize(object value) => JsonSerializer.Serialize(value, Options);

    public static string CamelCase(string propertyName) =>
        propertyName.Length == 0 ? propertyName : char.ToLowerInvariant(propertyName[0]) + propertyName[1..];
}
