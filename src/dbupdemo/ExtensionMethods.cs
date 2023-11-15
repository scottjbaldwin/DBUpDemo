
using System.Text.Json;
using System.Text.Json.Serialization;
using Amazon.SecretsManager;
using Amazon.SecretsManager.Model;
using MySql.Data.MySqlClient;

namespace dbupdemo;
public class DatabaseCredentials
{
    [JsonPropertyName("username")]
    public string Username { get; set; }

    [JsonPropertyName("password")]
    public string Password { get; set; }
}

public static class ExtensionMethods
{
    public static async Task<string> BuildFromEnvironmentVariables(this MySqlConnectionStringBuilder builder)
    {
        builder.Server = Environment.GetEnvironmentVariable("DBEndpoint");
        builder.Port = 3306;
        builder.Database = Environment.GetEnvironmentVariable("DBName");

        var secretsManager = new AmazonSecretsManagerClient();
        var secret = await secretsManager.GetSecretValueAsync(new GetSecretValueRequest
        {
            SecretId = Environment.GetEnvironmentVariable("DBSecret")
        });

        var credentials = JsonSerializer.Deserialize<DatabaseCredentials>(secret.SecretString);

        builder.UserID = credentials.Username;
        builder.Password = credentials.Password;
        builder.AllowUserVariables = true;

        return builder.ConnectionString;
    }
}