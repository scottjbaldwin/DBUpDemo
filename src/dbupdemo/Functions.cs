using System.Net;
using Amazon.Lambda.Core;
using Amazon.Lambda.APIGatewayEvents;
using DbUp;
using MySql.Data.MySqlClient;
using System.Reflection;
using Dapper;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace dbupdemo;

public class Functions
{
    /// <summary>
    /// Default constructor that Lambda will invoke.
    /// </summary>
    public Functions()
    {
    }


    /// <summary>
    /// A Lambda function to respond to HTTP Get methods from API Gateway
    /// </summary>
    /// <param name="request"></param>
    /// <returns>The API Gateway response.</returns>
    public APIGatewayProxyResponse Get(APIGatewayProxyRequest request, ILambdaContext context)
    {
        context.Logger.LogInformation("Get Request\n");

        var response = new APIGatewayProxyResponse
        {
            StatusCode = (int)HttpStatusCode.OK,
            Body = "Hello AWS Serverless",
            Headers = new Dictionary<string, string> { { "Content-Type", "text/plain" } }
        };

        return response;
    }

    public async Task SchemaUpgrade(SchemaUpgradeEvent evt, ILambdaContext context)
    {
        MySqlConnectionStringBuilder builder = new MySqlConnectionStringBuilder();
        context.Logger.LogInformation("creating connection string from environment variables");
        var connectionString = await builder.BuildFromEnvironmentVariables(context.Logger, false);

        await CreateDBIfNotExists(connectionString, context.Logger);

        connectionString = await builder.BuildFromEnvironmentVariables(context.Logger, true);
        context.Logger.LogInformation($"Schema Upgrade for build {evt.BuildIdentifier} initiated.");
        var upgrader = DeployChanges.To
                .MySqlDatabase(connectionString)
                .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly())
                .WithExecutionTimeout(TimeSpan.FromSeconds(300))
                .Build();

        context.Logger.LogInformation("Attempting to perform the upgrade");

        var result = upgrader.PerformUpgrade();

        if (!result.Successful)
        {
            context.Logger.LogError($"schema Upgrade failed, {result.Error.Message}");
        }
        else
        {
            context.Logger.LogInformation("Schema Upgrade successful.");
        }
    }

    public async Task CreateDBIfNotExists(string connectionString, ILambdaLogger logger)
    {
        using (var mysqlConnection = new MySqlConnection(connectionString))
        {
            logger.LogInformation("Opening connection to database to check for dbupdemo");
            await mysqlConnection.OpenAsync();

            logger.LogInformation("querying database to check for dbupdemo");
            var databases = await mysqlConnection.QueryAsync<string>("SHOW DATABASES;");
            logger.LogInformation($"Found {databases.Count()} databases");
            if (databases.FirstOrDefault(d => d == "dbupdemo") == null)
            {
                logger.LogWarning("database dbupdemo not found... creating");
                await mysqlConnection.ExecuteAsync("CREATE DATABASE dbupdemo;");
            }
            else
            {
                logger.LogInformation("database dbupdemo found");
            }
        }
    }

}