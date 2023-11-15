using System.Net;
using Amazon.Lambda.Core;
using Amazon.Lambda.APIGatewayEvents;
using DbUp;
using MySql.Data.MySqlClient;
using System.Reflection;

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
        var connectionString = await builder.BuildFromEnvironmentVariables();

        context.Logger.LogInformation($"Schema Upgrade for build {evt.BuildIdentifier} initiated.");
        var upgrader = DeployChanges.To
                .MySqlDatabase(connectionString)
                .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly())
                .WithExecutionTimeout(TimeSpan.FromSeconds(300))
                .Build();

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

}