// One JSON line per request so CloudWatch Logs Insights can parse fields automatically.
function requestLogger({ instanceId = process.env.INSTANCE_ID, log = console.log } = {}) {
  return (req, res, next) => {
    const start = process.hrtime.bigint();

    res.on('finish', () => {
      log(JSON.stringify({
        type: 'request',
        method: req.method,
        path: req.originalUrl,
        status: res.statusCode,
        durationMs: Number(process.hrtime.bigint() - start) / 1e6,
        userAgent: req.get('user-agent') || '',
        instanceId: instanceId || 'local',
      }));
    });

    next();
  };
}

module.exports = requestLogger;
