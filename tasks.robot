*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.FileSystem
Library           RPA.Archive
Library           RPA.Dialogs
Library           Collections
Library           RPA.Robocorp.Vault

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders

    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order 
        
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]

        Embed the robot screenshot to the receipt PDF file     ${screenshot}     ${pdf}     

        Go to order another robot
        #Sleep     10s    
    END
    Create a ZIP file of the receipts

*** Keywords ***
Open the robot order website
    ${secret}=    Get secret    Robot Spare Bin Industries WebSite
    Open Available Browser     ${secret}[URL]

Get orders
    Add heading    CSV File Url
    Add text input        CSVFileUrl    label=CSVFileUrl
    ${result}=    Run dialog
    #Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    Download    ${result.CSVFileUrl}    overwrite=True
        # Source dialect is deduced automatically
    ${readData}=   Read table from CSV    orders.csv
    [Return]   ${readData}

Close the annoying modal
    Click Element     css:button.btn-dark

Fill the form
    [Arguments]    ${row}
    Select From List By Index    id:head    ${row}[Head]
    Select Radio Button	   body     ${row}[Body]
    Input Text   	xpath://input[@placeholder='Enter the part number for the legs']    ${row}[Legs]
    Input Text      id:address       ${row}[Address]

Preview the robot
    Click Element     id:preview

Submit the order
    Wait Until Keyword Succeeds
    ...   1min    
    ...   1s
    ...   Click button Order

Click button Order
    Click Element     id:order
    Page Should Contain     Receipt
    #Click Element     id:order-another   

Store the receipt as a PDF file
    [Arguments]  ${surfix}
    Wait Until Element Is Visible    id:receipt
    ${sales_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${sales_results_html}    ${OUTPUT_DIR}${/}receipt_${surfix}.pdf

    [Return]    ./output/receipt_${surfix}.pdf
    
Take a screenshot of the robot
    [Arguments]  ${surfix}
    Wait Until Element Is Visible    id:robot-preview
    Screenshot	  id:robot-preview	     ${OUTPUTDIR}${/}robot-preview-${surfix}.PNG
    ${output_path} =  Set Variable     ./output/robot-preview-${surfix}.PNG
    [Return]    ${output_path}


Embed the robot screenshot to the receipt PDF file
    [Arguments]  ${screenshot}    ${pdf}

    Add Watermark Image To Pdf    
    ...             image_path=${screenshot}
    ...             source_path=${pdf}
    ...             output_path=${pdf} 

Go to order another robot
    Click Element     id:order-another

Create a ZIP file of the receipts
   Archive Folder With Zip    ./output    receipts.zip    include=*.pdf 