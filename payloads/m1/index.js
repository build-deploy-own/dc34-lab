// corp-logger-utils — internal logging utility
module.exports = {
  log: (msg) => console.log(`[corp-logger] ${msg}`),
  error: (msg) => console.error(`[corp-logger:error] ${msg}`)
};
