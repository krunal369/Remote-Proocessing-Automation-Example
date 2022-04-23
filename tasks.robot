*** Settings ***

*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Robocorp.Vault
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.Dialogs
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.Archive
Library           OperatingSystem
Library           RPA.Dialogs

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc.
    ${fileUrl}=    Get and log the value of the vault secrets using the Get Secret keyword
    Download the order excel file    ${fileUrl}
    ${url}=    Provide Interanet website
    Open the intranet website    ${url}
    Click Order your robot tab
    Fill the form using the data from the csv file
    Create ZIP package from PDF files
    [Teardown]    Close Browser

*** Keywords ***
Get and log the value of the vault secrets using the Get Secret keyword
    ${secret}=    Get Secret    OrderFileName
    [Return]    ${secret}[orderfilename]

Take orders file URL
    Add text input    orderfilename    label="Enter orders.csv file path"
    ${result}=    Run Dialog
    [Return]    ${result.orderfilename}

result

Download the order excel file
    [Arguments]    ${fileUrl}
    Download    ${fileUrl}    overwrite=True

Provide Interanet website
    Add text Input    url    label=Enter interanet Url
    ${result}=    Run Dialog
    [Return]    ${result.url}

Open the intranet website
    [Arguments]    ${url}
    Open Available Browser    ${url}    maximized=true

Click Order your robot tab
    Click Link    Order your robot!

Close the annoying modal
    Wait Until Element Is Visible    //button[text()='OK']
    Click Button    OK

Fill the form using the data from the csv file
    ${tables}=
    ...    Read Table From Csv
    ...    ${CURDIR}${/}orders.csv
    ...    header=True
    FOR    ${row}    IN    @{tables}
        Close the annoying modal
        Log    ${row}[Head]
        Log    ${row}[Order number]
        Select From List By Value    head    ${row}[Head]
        Select Radio Button    body    ${row}[Body]
        Input Text    //input[@type='number']    ${row}[Legs]
        Input Text    address    ${row}[Address]
        Click Button    //*[@id='preview']
        ${pdf}=    Wait Until Keyword Succeeds    10x    0.5s    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Click Button    //*[@id='order-another']
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}    ${row}[Order number]
    END

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}    ${row}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${OUTPUT_DIR}${/}${row}.pdf

Store the receipt as a PDF file
    [Arguments]    ${row}
    Click Button    //*[@id='order']
    ${receipt_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_results_html}    ${OUTPUT_DIR}${/}${row}.pdf
    [Return]    ${OUTPUT_DIR}${/}${row}.pdf

Take a screenshot of the robot
    [Arguments]    ${row}
    Wait Until Element Is Visible    //div[@id='robot-preview-image']
    Screenshot    //div[@id='robot-preview-image']    ${OUTPUT_DIR}${/}${row}.png
    [Return]    ${OUTPUT_DIR}${/}${row}.png

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}/PDFs.zip
    Archive Folder With Zip    ${OUTPUT_DIR}    ${zip_file_name}    include=*.pdf
    Log    ${zip_file_name}
