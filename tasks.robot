*** Settings ***

*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Robocorp.Vault
#Library          RPA.Robocloud.Secrets
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.Archive
Library           OperatingSystem
Library           RPA.Dialogs

*** Variables ***
${PDF_TEMP_OUTPUT_DIRECTORY}=    ${CURDIR}${/}temp

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc.
    ${fileUrl}=    Get and log the value of the vault secrets using the Get Secret keyword
    Download the order excel file    ${fileUrl}
    Create Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}
    Open the intranet website
    Click Order your robot tab
    Fill the form using the data from the csv file
    Create ZIP package from PDF files
    [Teardown]    Close Browser

*** Keywords ***
Get and log the value of the vault secrets using the Get Secret keyword
    ${secret}=    Get Secret    OrderFileName
    # Note: In real robots, you should not print secrets to the log.
    # This is just for demonstration purposes. :)
    [Return]    ${secret}[orderfilename]

Take orders file URL
    Add text input    orderfilename    label="Enter orders.csv file path"
    ${result}=    Run Dialog
    [Return]    ${result.orderfilename}

result

Download the order excel file
    [Arguments]    ${fileUrl}
    Download    ${fileUrl}    overwrite=True

Open the intranet website
    Open Available Browser    https://robotsparebinindustries.com/    maximized=true

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
    Log    ${screenshot}
    Log    ${pdf}
    Log    ${row}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${row}.pdf
    Remove File    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${row}.png

Store the receipt as a PDF file
    [Arguments]    ${row}
    Click Button    //*[@id='order']
    ${receipt_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_results_html}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${row}.pdf
    [Return]    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${row}.pdf

Take a screenshot of the robot
    [Arguments]    ${row}
    Wait Until Element Is Visible    //div[@id='robot-preview-image']
    Screenshot    //div[@id='robot-preview-image']    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${row}.png
    [Return]    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}${row}.png

Embed the robot screenshot to the receipt PDF file ${screenshot} ${pdf}
    Open Pdf ${pdf}

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${CURDIR}${/}/PDFs.zip
    Archive Folder With Zip    ${PDF_TEMP_OUTPUT_DIRECTORY}    ${zip_file_name}
    Log    ${zip_file_name}
