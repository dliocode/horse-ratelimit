# HorseRateLimit

Basic rate-limiting middleware for Horse. Use to limit repeated requests to public APIs and/or endpoints such as password reset.

### Stores

- Memory Store _(default, built-in)_ - stores hits in-memory in the Horse process. Does not share state with other servers or processes.

## Usage

For an API-only server where the ratelimit should be applied to all requests:

```delphi
uses Horse, Horse.RateLimit;
  
var
  App: THorse;
  RateLimit: THorseRateLimit;
begin
  App := THorse.Create(9000);
  
  RateLimit := THorseRateLimit.Create();

  App.Use(RateLimit.Limit)

  App.Get('/ping',    
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);
    
  App.Start;
end.
```

Create multiple instances to apply different rules to different routes:

```delphi
uses Horse, Horse.RateLimit;
  
var
  App: THorse;
  RLPing: THorseRateLimit;
  RLTest: THorseRateLimit;
  Config: TRateLimitConfig;
begin
  App := THorse.Create(9000);

  Config.Limit := 5; // Limit Request
  Config.Timeout := 30; // Timeout in seconds
  Config.Message := ''; // Message return
  Config.Headers := True; // Show in Header X-Rate-Limit-*
  Config.Store := nil; // Default TMemoryStore
  Config.SkipFailedRequest := False; // Undo if the response request was failed
  Config.SkipSuccessRequest := False; // Undo if the response request was successful

  RLPing := THorseRateLimit.Create(Config);

  App.Get('/ping',
    RLPing.Limit,
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  // Max of 30 Request in 5 minutes with return custom message
  Config.Limit := 30;
  Config.Timeout := 5 * 60;
  Config.Message := 'My Custom Message';
  Config.Headers := True;

  RLTest:= THorseRateLimit.Create(Config);
  App.Get('/test',
    RLTest.Limit,
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('ok');
    end);

  App.Start;
end.
```

**Note:** most stores will require additional configuration, such as custom prefixes, when using multiple instances. The default built-in memory store is an exception to this rule.

## Configuration options

### Limit

Max number of request during `Timeout` in seconds before sending a 429 response.

It must be a number. The default is `10`.

### Timeout

Timeframe for which requests are checked/remembered. Also used in the Retry-After header when the limit is reached.

Note: with non-default stores, you may need to configure this value twice, once here and once on the store. In some cases the units also differ (e.g. seconds vs miliseconds)

Defaults to `60` (1 minute).

### message

Error message sent to user when `Limit` is exceeded.

It must be a string. The default is `'Too many requests, please try again later.'`.

### headers

Enable headers for request limit (`X-Rate-Limit-Limit`) and current usage (`X-Rate-Limit-Remaining`) on all responses and time to wait before retrying (`Retry-After`) when `Limit` is exceeded.

Defaults to `false`. Behavior may change in the next major release.

### skipFailedRequests

When set to `true`, failed requests won't be counted. Request considered failed when:

- response status >= 400
- requests that were cancelled before last chunk of data was sent (response `close` event triggered)
- response `error` event was triggrered by response

(Technically they are counted and then un-counted, so a large number of slow requests all at once could still trigger a rate-limit. This may be fixed in a future release.)

Defaults to `false`.

### skipSuccessRequests

When set to `true` successful requests (response status < 400) won't be counted.
(Technically they are counted and then un-counted, so a large number of slow requests all at once could still trigger a rate-limit. This may be fixed in a future release.)

Defaults to `false`.

### skip

Function used to skip (whitelist) requests. Returning `true`, or a promise that resolves with `true`, from the function will skip limiting for that request.

Defaults to always `false` (count all requests):

```js
function (/*req, res*/) {
    return false;
}
```

### store

The storage to use when persisting rate limit attempts.

By default, the [MemoryStore](lib/memory-store.js) is used.

Available data stores are:

- MemoryStore: _(default)_ Simple in-memory option. Does not share state when app has multiple processes or servers.
- [rate-limit-redis](https://npmjs.com/package/rate-limit-redis): A [Redis](http://redis.io/)-backed store, more suitable for large or demanding deployments.
- [rate-limit-memcached](https://npmjs.org/package/rate-limit-memcached): A [Memcached](https://memcached.org/)-backed store.
- [rate-limit-mongo](https://www.npmjs.com/package/rate-limit-mongo): A [MongoDB](https://www.mongodb.com/)-backed store.

You may also create your own store. It must implement the following in order to function:

```js
function SomeStore() {
  /**
   * Increments the value in the underlying store for the given key.
   * @method function
   * @param {string} key - The key to use as the unique identifier passed
   *                     down from RateLimit.
   * @param {Function} cb - The callback issued when the underlying
   *                                store is finished.
   *
   * The callback should be called with three values:
   *  - error (usually null)
   *  - hitCount for this IP
   *  - resetTime - JS Date object (optional, but necessary for X-RateLimit-Reset header)
   */
  this.incr = function(key, cb) {
    // increment storage
    cb(null, hits, resetTime);
  };

  /**
   * Decrements the value in the underlying store for the given key. Used only when skipFailedRequests is true
   * @method function
   * @param {string} key - The key to use as the unique identifier passed
   *                     down from RateLimit.
   */
  this.decrement = function(key) {
    // decrement storage
  };

  /**
   * Resets a value with the given key.
   * @method function
   * @param  {[type]} key - The key to reset
   */
  this.resetKey = function(key) {
    // remove key from storage or reset it to 0
  };
}
```

## Instance API

### instance.resetKey(key)

Resets the rate limiting for a given key. (Allow users to complete a captcha or whatever to reset their rate limit, then call this method.)

## Summary of breaking changes:

### v5 changes

- Removed index.d.ts. (See [#138](https://github.com/nfriedly/express-rate-limit/issues/138))

### v4 Changes

- Express Rate Limit no longer modifies the passed-in options object, it instead makes a clone of it.

### v3 Changes

- Removed `delayAfter` and `delayMs` options; they were moved to a new module: [express-slow-down](https://npmjs.org/package/express-slow-down).
- Simplified the default `handler` function so that it no longer changes the response format. Now uses [res.send](https://expressjs.com/en/4x/api.html#res.send).
- `onLimitReached` now only triggers once for a given ip and window. only `handle` is called for every blocked request.

### v2 Changes

v2 uses a less precise but less resource intensive method of tracking hits from a given IP. v2 also adds the `limiter.resetKey()` API and removes the `global: true` option.

## License

MIT © [Nathan Friedly](http://nfriedly.com/)
