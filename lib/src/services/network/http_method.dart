/// Defines the standard HTTP methods for network requests.
/// این enum متدهای استاندارد HTTP را برای درخواست‌های شبکه تعریف می‌کند.
enum HttpMethod {
  /// The GET method requests a representation of the specified resource.
  /// Requests using GET should only retrieve data.
  get,

  /// The POST method is used to submit an entity to the specified resource,
  /// often causing a change in state or side effects on the server.
  post,

  /// The PUT method replaces all current representations of the target
  /// resource with the request payload.
  put,

  /// The DELETE method deletes the specified resource.
  delete,

  /// The PATCH method is used to apply partial modifications to a resource.
  patch,
}
