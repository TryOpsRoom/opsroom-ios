/// Build channel reported to the config API as the `environment` query parameter.
///
/// Must match the values your upgrade policy enables in the OpsRoom dashboard
/// (`enabledEnvironments` for debug, testflight, and production).
///
/// Raw values are lowercase strings on the wire (`debug`, `testflight`, `production`).
public enum AppEnvironment: String, Sendable {
    /// Local or Xcode debug builds. Wire value: `debug`.
    case debug

    /// TestFlight or internal beta builds. Wire value: `testflight`.
    case testFlight = "testflight"

    /// App Store or release builds. Wire value: `production`.
    case production
}
