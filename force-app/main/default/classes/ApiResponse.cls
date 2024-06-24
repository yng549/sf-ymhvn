global class ApiResponse {
    @AuraEnabled
    public Boolean success { get; set; }
    @AuraEnabled
    public object error { get; set; }
    @AuraEnabled
    public object result { get; set; }

    public ApiResponse() {
        this.success = false;
    }

    public ApiResponse(Boolean isSuccess) {
        this.success = isSuccess;
    }

    public void addError(String errorMessage) {
        if (this.error == null) {
            this.error = new Set<String>();
        }

        Set<String> errorList = (Set<String>) this.error;
        errorList.add(errorMessage);

        this.error = errorList;
    }
}