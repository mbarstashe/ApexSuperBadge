@isTest
global class WarehouseCalloutServiceMockFailure implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('Server Error');
        response.setStatusCode(500);
        return response; 
    }
}