@isTest
global class WarehouseCalloutServiceMockFailure implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('Server Error');
        response.setStatusCode(500);
        return response;
    }
}
