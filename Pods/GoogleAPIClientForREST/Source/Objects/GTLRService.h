/* Copyright (c) 2016 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Service object documentation:
// https://github.com/google/google-api-objectivec-client-for-rest/wiki#services-and-tickets

#import <Foundation/Foundation.h>

#import "GTLRDefines.h"
#import "GTLRBatchQuery.h"
#import "GTLRBatchResult.h"
#import "GTLRDateTime.h"
#import "GTLRErrorObject.h"
#import "GTLRObject.h"
#import "GTLRQuery.h"

#if !defined(GTLR_USE_FRAMEWORK_IMPORTS)
  #define GTLR_USE_FRAMEWORK_IMPORTS 0
#endif

#if GTLR_USE_FRAMEWORK_IMPORTS
  #import <GTMSessionFetcher/GTMSessionFetcher.h>
  #import <GTMSessionFetcher/GTMSessionFetcherService.h>
#else
  #import "GTMSessionFetcher.h"
  #import "GTMSessionFetcherService.h"
#endif  // GTLR_USE_FRAMEWORK_IMPORTS

NS_ASSUME_NONNULL_BEGIN

/**
 *  The domain used used for NSErrors created by GTLRService query execution.
 */
extern NSString *const kGTLRServiceErrorDomain;

typedef NS_ENUM(NSInteger, GTLRServiceError) {
  GTLRServiceErrorQueryResultMissing      = -3000,
  GTLRServiceErrorBatchResponseUnexpected = -3001,
  GTLRServiceErrorBatchResponseStatusCode = -3002
};

/**
 *  The kGTLRServiceErrorDomain userInfo key for the server response body.
 */
extern NSString *const kGTLRServiceErrorBodyDataKey;

/**
 *  The kGTLRServiceErrorDomain userInfo key for the response content ID, if appropriate.
 */
extern NSString *const kGTLRServiceErrorContentIDKey;

/**
 *  The domain used for foundation errors created from GTLRErrorObjects that
 *  were not originally foundation errors.
 */
extern NSString *const kGTLRErrorObjectDomain;

/**
 *  The userInfo key for the server error string for errors with domain kGTLRErrorObjectDomain.
 */
extern NSString *const kGTLRServiceErrorStringKey;

/**
 *  The userInfo key for a GTLRErrorObject for errors with domain kGTLRErrorObjectDomain
 *  when the error was created from a structured JSON error response body.
 */
extern NSString *const kGTLRStructuredErrorKey;

/**
 *  A constant ETag for when updating or deleting a single entry, telling
 *  the server to replace the current value unconditionally.
 *
 *  Do not use this in entries in a batch feed.
 */
extern NSString *const kGTLRETagWildcard;

/**
 *  Notification of a ticket starting.  The notification object is the ticket.
 *  This is posted on the main thread.
 *
 *  Use the stopped notification to log all requests made by the library.
 */
extern NSString *const kGTLRServiceTicketStartedNotification;

/**
 *  Notification of a ticket stopping.  The notification object is the ticket.
 *  This is posted on the main thread.
 */
extern NSString *const kGTLRServiceTicketStoppedNotification;

/**
 *  Notifications when parsing of a server response or entry begins.
 *  This is posted on the main thread.
 */
extern NSString *const kGTLRServiceTicketParsingStartedNotification;

/**
 *  Notifications when parsing of a server response or entry ends.
 *  This is posted on the main thread.
 */
extern NSString *const kGTLRServiceTicketParsingStoppedNotification;

@class GTLRServiceTicket;

/**
 *  Callback block for query execution.
 *
 *  @param callbackTicket The ticket that tracked query execution.
 *  @param object         The result of query execution. This will be derived from
 *                        GTLRObject. The object may be nil for operations such as DELETE which
 *                        do not return an object.  The object will be a GTLRBatchResult for
 *                        batch operations, and GTLRDataObject for media downloads.
 *  @param callbackError  If non-nil, the query execution failed.  For batch requests,
 *                        this may be nil even if individual queries in the batch have failed.
 */
typedef void (^GTLRServiceCompletionHandler)(GTLRServiceTicket *callbackTicket,
                                             id _Nullable object,
                                             NSError * _Nullable callbackError);

/**
 *  Callback block for upload of query data.
 *
 *  @param progressTicket             The ticket that tracks query execution.
 *  @param totalBytesUploaded         Number of bytes uploaded so far.
 *  @param totalBytesExpectedToUpload Number of bytes expected to be uploaded.
 */
typedef void (^GTLRServiceUploadProgressBlock)(GTLRServiceTicket *progressTicket,
                                               unsigned long long totalBytesUploaded,
                                               unsigned long long totalBytesExpectedToUpload);

/**
 *  Callback block invoked when an eror occurs during query execution.
 *
 *  @param retryTicket        The ticket that tracks query execution.
 *  @param suggestedWillRetry Flag indicating if the library would retry this without a retry block.
 *  @param fetchError         The error that occurred. If the domain is
 *                            kGTMSessionFetcherStatusDomain then the error's code is the server
 *                            response status.  Details on the error from the server are available
 *                            in the userInfo via the keys kGTLRStructuredErrorKey and
 *                            kGTLRServiceErrorStringKey.
 *
 *  @return YES if the request should be retried.
 */
typedef BOOL (^GTLRServiceRetryBlock)(GTLRServiceTicket *retryTicket,
                                      BOOL suggestedWillRetry,
                                      NSError * _Nullable fetchError);

/**
 *  Block to be invoked by a test block.
 *
 *  @param object The faked object, if any, to be passed to the test code's completion handler.
 *  @param error  The faked error if any, to be passed to the test code's completion handler.
 */
typedef void (^GTLRServiceTestResponse)(id _Nullable object, NSError *_Nullable error);

/**
 *  A test block enables testing of query execution without any network activity.
 *
 *  The test block must finish by calling the response block, passing either an object
 *  (GTLRObject or GTLRBatchResult) or an NSError.
 *
 *  The query is available to the test block code as testTicket.originalQuery.
 *
 *  Because query execution is asynchronous, the test code must wait for a callback,
 *  either with GTLRService's waitForTicket:timeout:fetchedObject:error: or with
 *  XCTestCase's waitForExpectationsWithTimeout:
 *
 *  Example usage is available in GTLRServiceTest.
 *
 *  @param testTicket   The ticket that tracks query execution.
 *  @param testResponse A block that must be invoked by the test block. This may be invoked
 *                      synchronously or asynchornously.
 */
typedef void (^GTLRServiceTestBlock)(GTLRServiceTicket *testTicket,
                                     GTLRServiceTestResponse testResponse);

#pragma mark -

/**
 *  Base class for the service that executes queries and manages tickets.
 *
 *  Client apps will typically use a generated subclass of GTLRService.
 */
@interface GTLRService : NSObject

#pragma mark Query Execution

/**
 *  Executes the supplied query
 *
 *  Success is indicated in the completion handler by a nil error parameter, not by a non-nil
 *  object parameter.
 *
 *  The callback block is invoked exactly once unless the ticket is cancelled.
 *  The callback will be called on the service's callback queue.
 *
 *  Various execution parameters will be taken from the service's properties, unless overridden
 *  in the query's @c executionParameters property.
 *
 *  A query may only be executed a single time. To reuse a query, make a copy before executing
 *  it.
 *
 *  To get a NSURLRequest that represents the query, use @c -[GTLRService requestForQuery:]
 *
 *  @param query   The API query, either a subclass of GTLRQuery, or a GTLRBatchQuery.
 *  @param handler The execution callback block.
 *
 *  @return A ticket for tracking or canceling query execution.
 */
- (GTLRServiceTicket *)executeQuery:(id<GTLRQueryProtocol>)query
                  completionHandler:(nullable GTLRServiceCompletionHandler)handler;

/**
 *  Executes the supplied query
 *
 *  The callback is invoked exactly once unless the ticket is cancelled.
 *  The callback will be called on the service's callbackQueue.
 *  Various execution parameters will be taken from the service's properties, unless overridden
 *  in the query's @c executionParameters property.
 *
 *  The selector should have a signature matching:
 *  @code
 *  - (void)serviceTicket:(GTLRServiceTicket *)callbackTicket
 *     finishedWithObject:(GTLRObject *)object
 *                  error:(NSError *)callbackError
 *  @endcode
 *
 *  @param query            The API query, either a subclass of GTLRQuery, or a GTLRBatchQuery.
 *  @param delegate         The object to be with the selector to be invoked upon completion.
 *  @param finishedSelector The selector to be invoked upon completion.
 *
 *  @return A ticket for tracking or canceling query execution.
 */
- (GTLRServiceTicket *)executeQuery:(id<GTLRQueryProtocol>)query
                           delegate:(nullable id)delegate
                  didFinishSelector:(nullable SEL)finishedSelector;


/**
 *  Enable automatic pagination.
 *
 *  A ticket can optionally do a sequence of fetches for queries where repeated requests
 *  with a @c nextPageToken query parameter is required to retrieve all pages of
 *  the response collection.  The client's callback is invoked only when all items have
 *  been retrieved, or an error has occurred.
 *
 *  The final object may be a combination of multiple page responses
 *  so it may not be the same as if all results had been returned in a single
 *  page. Some fields of the response may reflect only the final page's values.
 *
 *  Automatic page fetches will return an error if more than 25 page fetches are
 *  required.  For debug builds, this will log a warning to the console when more
 *  than 2 page fetches occur, as a reminder that the query's @c maxResults parameter
 *  should probably be increased to specify more items returned per page.
 *
 *  Automatic page accumulation is available for query result objects that are derived
 *  from GTLRCollectionObject.
 *
 *  This may also be specified for a single query in the query's @c executionParameters property.
 *
 *  Default value is NO.
 */
@property(nonatomic, assign) BOOL shouldFetchNextPages;

/**
 *  Some services require a developer key for quotas and limits.
 */
@property(nonatomic, copy, nullable) NSString *APIKey;

/**
 *  An authorizer adds user authentication headers to the request as needed.
 *
 *  This may be overridden on individual queries with the @c shouldSkipAuthorization property.
 */
@property(nonatomic, retain, nullable) id <GTMFetcherAuthorizationProtocol> authorizer;

/**
 *  Enable fetcher retry support.  See the explanation of retry support in @c GTMSessionFetcher.h
 *
 *  Default value is NO, but retry is also enabled if the retryBlock is not nil.
 *
 *  This may also be specified for a single query in the query's @c executionParameters property.
 */
@property(nonatomic, assign, getter=isRetryEnabled) BOOL retryEnabled;

/**
 *  A retry block may be provided to inspect and change retry criteria.
 *
 *  This may also be specified for a single query in the query's @c executionParameters property.
 */
@property(copy, nullable) GTLRServiceRetryBlock retryBlock;

/**
 *  The maximum retry interval. Retries occur at increasing intervals, up to the specified maximum.
 *
 *  This may also be specified for a single query in the query's @c executionParameters property.
 */
@property(nonatomic, assign) NSTimeInterval maxRetryInterval;

#pragma mark Fetch Object by Resource URL

/**
 *  Fetch an object given the resource URL. This is appropriate when the object's
 *  full link is known, such as from a selfLink response property.
 *
 *  @param resourceURL         The URL of the object to be fetched.
 *  @param objectClass         The GTLRObject subclass to be instantiated. If nil, the library
 *                             will try to infer the class from the object's "kind" string property.
 *  @param executionParameters Values to override the service's properties when executing the
 *                             ticket.
 *  @param handler             The execution callback block.
 *
 *  @return A ticket for tracking or canceling query execution.
 */
- (GTLRServiceTicket *)fetchObjectWithURL:(NSURL *)resourceURL
                              objectClass:(nullable Class)objectClass
                      executionParameters:(nullable GTLRServiceExecutionParameters *)executionParameters
                        completionHandler:(nullable GTLRServiceCompletionHandler)handler;

#pragma mark Support for Client Tests

/**
 *  A test block can be provided to test service calls without any network activity.
 *
 *  See the description of @c GTLRServiceTestBlock for additional details.
 *
 *  This may also be specified for a single query in the query's @c executionParameters property.
 *
 *  A service instance for testing can also be created with @c +mockServiceWithFakedObject
 */
@property(nonatomic, copy, nullable) GTLRServiceTestBlock testBlock;

#pragma mark Converting a Query to an NSURLRequest

/**
 *  Creates a NSURLRequest from the query object and from properties on this service
 *  (additionalHTTPHeaders, additionalURLQueryParameters, APIKey) without executing
 *  it. This can be useful for using @c GTMSessionFetcher or @c NSURLSession to
 *  perform the fetch.
 *
 *  For requests to non-public resources, the request will not yet be authorized;
 *  that can be done using the GTLR service's authorizer. Creating a @c GTMSessionFetcher
 *  from the GTLRService's @c fetcherService will take care of authorization as well.
 *
 *  This works only for GET queries, and only for an individual query, not a batch query.
 *
 *  @note @c Unlike executeQuery:, requestForQuery: does not release the query's callback blocks.
 *
 *  @param query The query used to create the request.
 *
 *  @return A request suitable for use with @c GTMSessionFetcher or @c NSURLSession
 */
- (NSMutableURLRequest *)requestForQuery:(GTLRQuery *)query;

#pragma mark User Properties

/**
 *  The service properties dictionary is copied to become the initial property dictionary
 *  for each ticket, augmented by a query's execution parameter's properties.
 */
@property(nonatomic, copy, nullable) NSDictionary<NSString *, id> *serviceProperties;

#pragma mark JSON to GTLRObject Mapping

/**
 * Specifies subclasses to be created instead of standard library objects, allowing
 * an app to add properties and methods to GTLR objects.
 *
 * This is just a helper method that sets the service's objectClassResolver:.
 *
 * Example:
 * @code
 *  NSDictionary *surrogates = @{
 *    [MyDriveFile class]     : [GTLRDrive_File_Surrogate class],
 *    [MyDriveFileList class] : [GTLRDrive_FileList_Surrogate class]
 *  };
 *  [service setSurrogates:surrogates];
 * @endcode
 */
- (void)setSurrogates:(NSDictionary <Class, Class>*)surrogates;

/**
 *  Used to decide what GTLRObject subclass to make from the received JSON.
 *
 *  This defaults to a resolver that will use any kindStringToClassMap the service
 *  provides.
 *
 *  To use a standard resolver with a surrogates dictionary, invoke setSurrogates: instead
 *  of setting this property.
 */
@property(nonatomic, strong) id<GTLRObjectClassResolver> objectClassResolver;

/**
 *  A dictionary mapping "kind" strings to the GTLObject subclasses that should
 *  be created for JSON with the given kind.
 */
+ (NSDictionary<NSString *, Class> *)kindStringToClassMap;

#pragma mark Request Settings

/**
 *  The queue used to invoked callbacks. By default, the main queue is used for callbacks.
 */
@property(nonatomic, retain) dispatch_queue_t callbackQueue;

/**
 *  Allows the application to make non-SSL and localhost requests for testing.
 *
 *  Default value is NO.
 */
@property(nonatomic, assign) BOOL allowInsecureQueries;

/**
 *  The fetcher service creates the fetcher instances for this API service.
 *
 *  Applications may set this to an authorized fetcher service created elsewhere
 *  in the app, or may take the fetcher service created by this GTLRService and use it
 *  to create fetchers independent of this service.
 */
@property(nonatomic, retain) GTMSessionFetcherService *fetcherService;

#pragma mark Custom User Agents

/**
 *  Applications needing an additional identifier in the server logs may specify one.
 */
@property(nonatomic, copy, nullable) NSString *userAgentAddition;

/**
 *  A user-agent based on the application signature in the Info.plist settings.
 *
 *  Most applications should not explicitly set this property.  Any string provided will
 *  be cleaned of inappropriate characters.
 */
@property(nonatomic, copy, nullable) NSString *userAgent;

/**
 * The request user agent includes the library and OS version appended to the
 * base userAgent, along with the optional addition string.
 */
@property(nonatomic, readonly, nullable) NSString *requestUserAgent;

/**
 *  A precise userAgent string identifying the application.  No cleaning of characters is done.
 *  Library-specific details will be appended.
 *
 *  @param userAgent A wire-ready use agent string.
 */
- (void)setExactUserAgent:(nullable NSString *)userAgent;

/**
 *  Any additional URL query parameters for the queries executed by this service.
 *
 *  Individual queries may have additionalURLQueryParameters specified as well.
 */
@property(copy, nullable) NSDictionary<NSString *, NSString *> *additionalURLQueryParameters;

/**
 *  Any additional HTTP headers for this queries executed by this service.
 *
 *  Individual queries may have additionalHTTPHeaders specified as well.
 */
@property(copy, nullable) NSDictionary<NSString *, NSString *> *additionalHTTPHeaders;

#pragma mark Request URL Construction

/*
 * The URL for where to send a Query is built out of these parts
 * ( https://developers.google.com/discovery/v1/using#build-compose ) :
 *
 *   service.rootURLString + service.servicePath + query.pathURITemplate
 *
 * Note: odds are these both should end in a '/', so make sure any value you
 * provide will combine correctly with the above rules.
 */

/**
 *  The scheme and host for the API server.  This may be modified to point at a test server.
 */
@property(nonatomic, copy) NSString *rootURLString;

/**
 *  The path for the specific API service instance, relative to the rootURLString.
 */
@property(nonatomic, copy) NSString *servicePath;

/**
 *  A path fragment added in to URLs before "servicePath" to build
 *  the full URL used for resumable media uploads.
 */
@property(nonatomic, copy) NSString *resumableUploadPath;

/**
 *  A path fragment added in to URLs before "servicePath" to build
 *  the full URL used for simple and multipart media uploads.
 */
@property(nonatomic, copy) NSString *simpleUploadPath;

/**
 *  A path fragment added in to URLs before "servicePath" to build
 *  the full URL used for batch requests.
 */
@property(nonatomic, copy) NSString *batchPath;

#pragma mark Resumable Uploads

/**
 *  A block called to track upload progress.
 *
 *  A query's service execution parameters may be used to override this.
 */
@property(copy, nullable) GTLRServiceUploadProgressBlock uploadProgressBlock;

/**
 *  The default chunk size for resumable uploads.  This defaults to kGTLRStandardUploadChunkSize
 *  for service subclasses that support chunked uploads.
 */
@property(nonatomic, assign) NSUInteger serviceUploadChunkSize;

/**
 *  Service subclasses may override this to specify their own default chunk size for
 *  resumable uploads.
 */
+ (NSUInteger)defaultServiceUploadChunkSize;

#pragma mark Internal
/////////////////////////////////////////////////////////////////////////////////////////////
//
// Properties below are used by the library and should not typically be set by client apps.
//
/////////////////////////////////////////////////////////////////////////////////////////////

/**
 *  The queue used for parsing JSON responses.
 *
 *  Applications should typically not change this.
 */
@property(nonatomic, retain) dispatch_queue_t parseQueue;

/**
 *  If this service supports pretty printing the JSON on the wire, these are
 *  the names of the query params that enable it. The library disables
 *  pretty printing to save on bandwidth.
 *
 *  Applications should typically not change this.
 */
@property(nonatomic, strong) NSArray<NSString *> *prettyPrintQueryParameterNames;

/**
 *  This indicates if the API requires a "data" JSON element to wrap the payload
 *  on requests and responses.
 *
 *  Applications should typically not change this.
 */
@property(nonatomic, assign, getter=isDataWrapperRequired) BOOL dataWrapperRequired;

@end

@interface GTLRService (TestingSupport)

/**
 *  Convenience method to create a mock GTLR service just for testing.
 *
 *  Queries executed by this mock service will not perform any network operation,
 *  but will invoke callbacks and provide the supplied object or error to the
 *  completion handler.
 *
 *  You can make more customized mocks by setting the test block property of a service
 *  or a query's execution parameters.  The test block can inspect the query as ticket.originalQuery
 *  to customize test behavior.
 *
 *  See the description of @c GTLRServiceTestBlock for more details on customized testing.
 *
 *  Example usage is in the unit test method @c testService_MockService_Succeeding
 *
 *  @param objectOrNil An object derived from GTLRObject to be passed to query completion handlers.
 *  @param error       An error to be passed to query completion handlers.
 *
 *  @return A mock instance of the service, suitable for unit testing.
 */
+ (instancetype)mockServiceWithFakedObject:(nullable id)object
                                fakedError:(nullable NSError *)error;

/**
 *  Wait synchronously for fetch to complete (strongly discouraged)
 *
 *  This method is intended for use only in unit tests and command-line tools.
 *  Unit tests may also use XCTest's waitForExpectationsWithTimeout: instead of
 *  or after this method.
 *
 *  This method just runs the current event loop until the fetch completes
 *  or the timout limit is reached.  This may discard unexpected events
 *  that occur while spinning, so it's really not appropriate for use
 *  in serious applications.
 *
 *  Returns YES if an object was successfully fetched.  If the wait
 *  timed out, returns NO and the returned error is nil.
 *
 *  @param ticket           The ticket being executed.
 *  @param timeoutInSeconds Maximum duration to wait.
 *
 *  @return YES if the ticket completed or was cancelled; NO if the wait timed out.
 */
- (BOOL)waitForTicket:(GTLRServiceTicket *)ticket
              timeout:(NSTimeInterval)timeoutInSeconds;

@end

#pragma mark -

/**
 *  Service execution parameters may be set on an individual query
 *  to alter the service's settings.
 */
@interface GTLRServiceExecutionParameters : NSObject<NSCopying>

/**
 *  Override the service's property @c shouldFetchNextPages for automatic pagination.
 *
 *  A BOOL value should be specified.
 */
@property(nonatomic) NSNumber *shouldFetchNextPages;

/**
 *  Override the service's property @c shouldFetchNextPages for enabling automatic retries.
 *
 *  A BOOL value should be specified.
 *
 *  Retry is also enabled if the retryBlock is not nil
 */
@property(nonatomic, getter=isRetryEnabled) NSNumber *retryEnabled;

/**
 *  Override the service's property @c retryBlock for customizing automatic retries.
 */
@property(copy, nullable) GTLRServiceRetryBlock retryBlock;

/**
 *  Override the service's property @c maxRetryInterval for customizing automatic retries.
 *
 *  A NSTimeInterval (double) value should be specified.
 */
@property(atomic) NSNumber *maxRetryInterval;

/**
 *  Override the service's property @c uploadProgressBlock for monitoring upload progress.
 */
@property(copy, nullable) GTLRServiceUploadProgressBlock uploadProgressBlock;

/**
 *  Override the service's property @c callbackQueue for invoking callbacks.
 */
@property(retain, nullable) dispatch_queue_t callbackQueue;

/**
 *  Override the service's property @c testBlock for simulating query execution.
 *
 *  See the description of @c GTLRServiceTestBlock for additional details.
 */
@property(copy, nullable) GTLRServiceTestBlock testBlock;

/**
 *  Override the service's property @c objectClassResolver for controlling object class selection.
 */
@property(atomic, strong) id<GTLRObjectClassResolver> objectClassResolver;

/**
 *  The ticket's properties are the service properties, with the execution parameter's
 *  ticketProperties added (replacing any keys already present from the service.)
 */
@property(atomic, copy, nullable) NSDictionary<NSString *, id> *ticketProperties;

/**
 *  Indicates if any of the execution parameters properties are set.
 */
@property(nonatomic, readonly) BOOL hasParameters;

@end

/**
 *  A ticket tracks the progress of a query being executed.
 */
@interface GTLRServiceTicket : NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 *  The service that issued this ticket.
 *
 *  This method may be invoked from any thread.
 */
@property(atomic, readonly) GTLRService *service;

#pragma mark Execution Control

/**
 *  Invoking cancelTicket stops the fetch if it is in progress.  The query callbacks
 *  will not be invoked.
 *
 *  This method may be invoked from any thread.
 */
- (void)cancelTicket;

/**
 *  The time the ticket was created.
 */
@property(atomic, readonly) NSDate *creationDate;

/**
 *  Pause the ticket execution. This is valid only for chunked, resumable upload queries.
 */
- (void)pauseUpload;

/**
 *  Resume the ticket execution. This is valid only for chunked, resumable upload queries.
 */
- (void)resumeUpload;

/**
 *  Checks if the ticket execution is paused.
 */
@property(nonatomic, readonly, getter=isUploadPaused) BOOL uploadPaused;

/**
 *  The request being fetched for the query.
 */
@property(nonatomic, readonly, nullable) NSURLRequest *fetchRequest;

/**
 *  The fetcher being used for the query request.
 */
@property(atomic, readonly, nullable) GTMSessionFetcher *objectFetcher;

/**
 *  The queue used for query callbacks.
 */
@property(atomic, readonly) dispatch_queue_t callbackQueue;

/**
 *  The API key used for the query requeat.
 */
@property(atomic, readonly, nullable) NSString *APIKey;

#pragma mark Status

/**
 *  The server's response status for the query's fetch, if available.
 */
@property(nonatomic, readonly) NSInteger statusCode;

/**
 *  The error resulting from the query's fetch, if available.
 */
@property(nonatomic, readonly, nullable) NSError *fetchError;

/**
 *  A flag indicating if the query's callbacks have been invoked.
 */
@property(nonatomic, readonly) BOOL hasCalledCallback;

/**
 *  A flag indicating if the query execution was cancelled by the client app.
 */
@property(atomic, readonly, getter=isCancelled) BOOL cancelled;

#pragma mark Pagination

/**
 *  A flag indicating if automatic pagination is enabled for the query.
 */
@property(nonatomic, readonly) BOOL shouldFetchNextPages;

/**
 *  The number of pages fetched, if automatic pagination is enabled for the query and multiple
 *  pages have been fetched.
 */
@property(nonatomic, readonly) NSUInteger pagesFetchedCounter;

#pragma mark User Properties

/**
 *  Ticket properties a way to pass values via the ticket for the convenience of the client app.
 *
 *  Ticket properties are initialized from serviceProperties and augmented by the ticketProperties
 *  of the query's execution parameters.
 */
@property(nonatomic, readonly, nullable) NSDictionary<NSString *, id> *ticketProperties;

#pragma mark Payload

/**
 *  The object being uploaded via POST, PUT, or PATCH.
 */
@property(nonatomic, readonly, nullable) GTLRObject *postedObject;

/**
 *  The object downloaded for the query, after parsing.
 */
@property(nonatomic, readonly, nullable) GTLRObject *fetchedObject;

/**
 *  The query currently being fetched by this ticket. This may not be the original query when
 *  fetching a second or later pages.
 */
@property(atomic, readonly, nullable) id<GTLRQueryProtocol> executingQuery;

/**
 *  The query used to create this ticket
 */
@property(atomic, readonly, nullable) id<GTLRQueryProtocol> originalQuery;

/**
 *  The @c GTLRObjectClassResolver for controlling object class selection.
 */
@property(atomic, readonly, strong) id<GTLRObjectClassResolver> objectClassResolver;

/**
 *  The query from within the ticket's batch request with the given ID.
 *
 *  @param requestID The desired ticket's request ID.
 *
 *  @return The query with the specified ID, if found.
 */
- (nullable GTLRQuery *)queryForRequestID:(NSString *)requestID;

@end

NS_ASSUME_NONNULL_END
