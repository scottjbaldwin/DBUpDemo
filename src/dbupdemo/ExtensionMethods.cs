
using System.Text.Json;
using System.Text.Json.Serialization;
using Amazon.Lambda.Core;
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
    public static async Task<string> BuildFromEnvironmentVariables(this MySqlConnectionStringBuilder builder, ILambdaLogger logger, bool includeDbName)
    {
        builder.Server = Environment.GetEnvironmentVariable("DBEndpoint");
        builder.Port = 3306;
        if (includeDbName)
        {
            builder.Database = Environment.GetEnvironmentVariable("DBName");
        }
        var secretId = Environment.GetEnvironmentVariable("DBSecret");

        logger.LogInformation($"Getting secret value from secret: {secretId}");

        var config = new AmazonSecretsManagerConfig();
        config.ServiceURL = "https://secretsmanager.ap-southeast-2.amazonaws.com";

        var secretsManager = new AmazonSecretsManagerClient(config);
        var secret = await secretsManager.GetSecretValueAsync(new GetSecretValueRequest
        {
            SecretId =  secretId
        });

        logger.LogInformation($"Retrieved secret string: {secret.SecretString}");

        var credentials = JsonSerializer.Deserialize<DatabaseCredentials>(secret.SecretString);

        builder.UserID = credentials.Username;
        builder.Password = credentials.Password;
        builder.AllowUserVariables = true;

        return builder.ConnectionString;
    }
}