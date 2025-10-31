using Amazon.Lambda.Core;
using DbUp.Engine.Output;
using Microsoft.Extensions.Logging;

namespace ropp.Pipeline.Schema
{
    public class UpgradeLoggerWrapper : IUpgradeLog
    {
        private readonly ILambdaLogger _logger;

        public UpgradeLoggerWrapper(ILambdaLogger logger)
        {
            _logger = logger;
        }

        public void WriteError(string format, params object[] args)
            => _logger.LogError(String.Format(format, args));

        public void WriteInformation(string format, params object[] args)
            => _logger.LogInformation(format, args);

        public void WriteWarning(string format, params object[] args)
            => _logger.LogWarning(format, args);
    }
}