*** Settings ***
Documentation       Bulk load Account objects into Salesforce using QForce API keywords
...                 This script demonstrates API-based data loading without UI interaction
Resource            common.resource

*** Variables ***
${json_file_path}           ${CURDIR}/resources/bulk_accounts.json
${client_id}                YOUR_CONSUMER_KEY_HERE
${client_secret}            YOUR_CONSUMER_SECRET_HERE  
${domain}                   yourdomain.my.salesforce.com

*** Test Cases ***
bulk_load_accounts_to_salesforce
    [Documentation]         Creates multiple Account records via Salesforce API using bulk import
    [Tags]                  api    bulk_load    accounts
    [Setup]                 authenticate_to_salesforce_api
    [Teardown]              log_test_completion
    
    TRY
        ${import_result}=       Import Records      Account     ${json_file_path}
        Log To Console          Bulk import successful. Response: ${import_result}
        
        # Extract IDs from the API response
        @{created_ids}=         Evaluate            [x['id'] for x in $import_result['results']]
        ${record_count}=        Get Length          ${created_ids}
        Log To Console          Created ${record_count} Account records
        
        # Verify each created Account exists
        FOR    ${account_id}    IN    @{created_ids}
            ${account_data}=    Get Record          Account     ${account_id}
            Log To Console      Verified Account: ${account_data}[Name] (ID: ${account_id})
            Should Not Be Empty    ${account_data}[Name]
        END
        
        Log To Console          All ${record_count} Accounts verified successfully
        
    EXCEPT    AS    ${error}
        ${today}=               Get Current Date    result_format=%Y-%m-%d
        ${log_file}=            Set Variable        ${CURDIR}/../../output/log-${today}.txt
        Append To File          ${log_file}         [ERROR] ${error}\n
        Log To Console          ERROR: ${error}
        Fail                    Bulk Account load failed: ${error}
    END

*** Keywords ***
authenticate_to_salesforce_api
    [Documentation]         Authenticates to Salesforce REST API using Client Credentials Flow
    ...                     Reference: QForce "Client Authenticate" keyword documentation
    ...                     Uses OAuth 2.0 Client Credentials Flow which is recommended over 
    ...                     deprecated username-password flow
    Client Authenticate     ${domain}    ${client_id}    ${client_secret}    timeout=10
    Log To Console          Successfully authenticated to Salesforce API

log_test_completion
    [Documentation]         Logs test completion timestamp
    ${timestamp}=           Get Current Date    result_format=%Y-%m-%d %H:%M:%S
    Log To Console          Test completed at: ${timestamp}