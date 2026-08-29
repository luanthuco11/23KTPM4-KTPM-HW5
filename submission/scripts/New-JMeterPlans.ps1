[CmdletBinding()]
param(
    [string]$ExecutionDate = (Get-Date -Format 'yyyyMMdd'),

    [ValidateSet('Load', 'Stress', 'Spike', 'Soak')]
    [string[]]$Scenarios = @('Load', 'Stress', 'Spike', 'Soak')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent $PSScriptRoot
$planDirectory = Join-Path $projectRoot 'test-plans'
New-Item -ItemType Directory -Force -Path $planDirectory | Out-Null

function New-StatusAssertionXml {
    param([string]$Message)

    return @"
<ResponseAssertion guiclass="AssertionGui" testclass="ResponseAssertion" testname="Assert HTTP 200">
  <collectionProp name="Asserion.test_strings">
    <stringProp name="200">200</stringProp>
  </collectionProp>
  <stringProp name="Assertion.custom_message">$Message</stringProp>
  <stringProp name="Assertion.test_field">Assertion.response_code</stringProp>
  <boolProp name="Assertion.assume_success">false</boolProp>
  <intProp name="Assertion.test_type">8</intProp>
</ResponseAssertion>
<hashTree/>
"@
}

function New-BodyAssertionXml {
    param(
        [string]$Name,
        [string]$ExpectedText
    )

    return @"
<ResponseAssertion guiclass="AssertionGui" testclass="ResponseAssertion" testname="$Name">
  <collectionProp name="Asserion.test_strings">
    <stringProp name="expected">$ExpectedText</stringProp>
  </collectionProp>
  <stringProp name="Assertion.custom_message">Expected response content was not found.</stringProp>
  <stringProp name="Assertion.test_field">Assertion.response_data</stringProp>
  <boolProp name="Assertion.assume_success">false</boolProp>
  <intProp name="Assertion.test_type">16</intProp>
</ResponseAssertion>
<hashTree/>
"@
}

function New-JsonExtractorXml {
    param(
        [string]$Name,
        [string]$References,
        [string]$Expressions,
        [string]$Matches,
        [string]$Defaults
    )

    return @"
<JSONPostProcessor guiclass="JSONPostProcessorGui" testclass="JSONPostProcessor" testname="$Name">
  <stringProp name="JSONPostProcessor.referenceNames">$References</stringProp>
  <stringProp name="JSONPostProcessor.jsonPathExprs">$Expressions</stringProp>
  <stringProp name="JSONPostProcessor.match_numbers">$Matches</stringProp>
  <stringProp name="JSONPostProcessor.defaultValues">$Defaults</stringProp>
</JSONPostProcessor>
<hashTree/>
"@
}

function New-SamplerXml {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Path,
        [string]$ArgumentsXml,
        [string]$ChildrenXml
    )

    return @"
<HTTPSamplerProxy guiclass="HttpTestSampleGui" testclass="HTTPSamplerProxy" testname="$Name">
  <elementProp name="HTTPsampler.Arguments" elementType="Arguments" guiclass="HTTPArgumentsPanel" testclass="Arguments" testname="User Defined Variables">
    <collectionProp name="Arguments.arguments">
$ArgumentsXml
    </collectionProp>
  </elementProp>
  <stringProp name="HTTPSampler.domain"></stringProp>
  <stringProp name="HTTPSampler.port"></stringProp>
  <stringProp name="HTTPSampler.protocol"></stringProp>
  <stringProp name="HTTPSampler.contentEncoding">UTF-8</stringProp>
  <stringProp name="HTTPSampler.path">$Path</stringProp>
  <stringProp name="HTTPSampler.method">$Method</stringProp>
  <boolProp name="HTTPSampler.follow_redirects">true</boolProp>
  <boolProp name="HTTPSampler.auto_redirects">false</boolProp>
  <boolProp name="HTTPSampler.use_keepalive">true</boolProp>
  <boolProp name="HTTPSampler.DO_MULTIPART_POST">false</boolProp>
  <boolProp name="HTTPSampler.postBodyRaw">$($Method -eq 'POST')</boolProp>
  <stringProp name="HTTPSampler.embedded_url_re"></stringProp>
  <stringProp name="HTTPSampler.connect_timeout">5000</stringProp>
  <stringProp name="HTTPSampler.response_timeout">10000</stringProp>
</HTTPSamplerProxy>
<hashTree>
$ChildrenXml
</hashTree>
"@
}

function New-RawBodyArgumentXml {
    param([string]$Body)

    return @"
      <elementProp name="" elementType="HTTPArgument">
        <boolProp name="HTTPArgument.always_encode">false</boolProp>
        <stringProp name="Argument.value">$Body</stringProp>
        <stringProp name="Argument.metadata">=</stringProp>
      </elementProp>
"@
}

function New-QueryArgumentXml {
    param(
        [string]$Name,
        [string]$Value
    )

    return @"
      <elementProp name="$Name" elementType="HTTPArgument">
        <boolProp name="HTTPArgument.always_encode">true</boolProp>
        <stringProp name="Argument.value">$Value</stringProp>
        <stringProp name="Argument.metadata">=</stringProp>
        <boolProp name="HTTPArgument.use_equals">true</boolProp>
        <stringProp name="Argument.name">$Name</stringProp>
      </elementProp>
"@
}

function New-WorkflowXml {
    $status = New-StatusAssertionXml -Message 'Expected HTTP 200.'

    $loginBody = New-RawBodyArgumentXml -Body '{&quot;email&quot;:&quot;${email}&quot;,&quot;password&quot;:&quot;${password}&quot;}'
    $loginChildren = $status + (New-BodyAssertionXml -Name 'Assert login token field' -ExpectedText '&quot;token&quot;') + (New-JsonExtractorXml -Name 'Extract JWT' -References 'authToken' -Expressions '$.token' -Matches '1' -Defaults 'NOT_FOUND')
    $login = New-SamplerXml -Name '01 Login (auth-heavy)' -Method 'POST' -Path '/api/login' -ArgumentsXml $loginBody -ChildrenXml $loginChildren

    $searchArguments = New-QueryArgumentXml -Name 'search' -Value '${searchTerm}'
    $searchChildren = $status + (New-JsonExtractorXml -Name 'Extract product data' -References 'productId;productPrice;productName' -Expressions '$[0].id;$[0].price;$[0].name' -Matches '1;1;1' -Defaults 'NOT_FOUND;0;NOT_FOUND')
    $search = New-SamplerXml -Name '02 Search products (read-heavy)' -Method 'GET' -Path '/api/products' -ArgumentsXml $searchArguments -ChildrenXml $searchChildren

    $detail = New-SamplerXml -Name '03 View product detail (read-heavy)' -Method 'GET' -Path '/api/products/${productId}' -ArgumentsXml '' -ChildrenXml $status
    $viewCart = New-SamplerXml -Name '04 View cart (read-heavy)' -Method 'GET' -Path '/api/cart' -ArgumentsXml '' -ChildrenXml $status

    $cartBody = New-RawBodyArgumentXml -Body '{&quot;productId&quot;:${productId},&quot;name&quot;:&quot;${productName}&quot;,&quot;price&quot;:${productPrice},&quot;quantity&quot;:${quantity}}'
    $cartChildren = $status + (New-BodyAssertionXml -Name 'Assert add-to-cart success' -ExpectedText 'Added to cart')
    $addCart = New-SamplerXml -Name '05 Add product to cart (transactional)' -Method 'POST' -Path '/api/cart' -ArgumentsXml $cartBody -ChildrenXml $cartChildren

    $checkoutBody = New-RawBodyArgumentXml -Body '{&quot;total_amount&quot;:${__groovy(vars.get(&quot;productPrice&quot;).toBigDecimal().multiply(vars.get(&quot;quantity&quot;).toBigDecimal()).intValue())},&quot;shipping_address&quot;:&quot;${shippingAddress}&quot;}'
    $checkoutChildren = $status + (New-BodyAssertionXml -Name 'Assert checkout success' -ExpectedText 'Checkout successful') + (New-JsonExtractorXml -Name 'Extract order ID' -References 'orderId' -Expressions '$.orderId' -Matches '1' -Defaults 'NOT_FOUND')
    $checkout = New-SamplerXml -Name '06 Checkout (transactional)' -Method 'POST' -Path '/api/checkout' -ArgumentsXml $checkoutBody -ChildrenXml $checkoutChildren

    $ordersChildren = $status + (New-BodyAssertionXml -Name 'Assert created order appears in history' -ExpectedText '&quot;id&quot;:${orderId}')
    $orders = New-SamplerXml -Name '07 View order history (verification)' -Method 'GET' -Path '/api/orders/my-orders' -ArgumentsXml '' -ChildrenXml $ordersChildren

    return @"
<TransactionController guiclass="TransactionControllerGui" testclass="TransactionController" testname="E2E Purchase Workflow">
  <boolProp name="TransactionController.includeTimers">true</boolProp>
  <boolProp name="TransactionController.parent">true</boolProp>
</TransactionController>
<hashTree>
  <UniformRandomTimer guiclass="UniformRandomTimerGui" testclass="UniformRandomTimer" testname="Realistic think time 400-1000 ms">
    <stringProp name="ConstantTimer.delay">400</stringProp>
    <stringProp name="RandomTimer.range">600</stringProp>
  </UniformRandomTimer>
  <hashTree/>
$login
$search
$detail
$viewCart
$addCart
$checkout
$orders
</hashTree>
"@
}

function New-ThreadGroupXml {
    param(
        [string]$Name,
        [int]$Threads,
        [int]$RampSeconds,
        [int]$DurationSeconds,
        [int]$DelaySeconds,
        [string]$CsvFile,
        [string]$PropertyPrefix
    )

    $workflow = New-WorkflowXml
    $propertyKey = $PropertyPrefix.Replace('.', '_')
    $threadExpression = '${__P(' + $propertyKey + '_threads,' + $Threads + ')}'
    $rampExpression = '${__P(' + $propertyKey + '_ramp,' + $RampSeconds + ')}'
    $durationExpression = '${__P(' + $propertyKey + '_duration,' + $DurationSeconds + ')}'
    $delayExpression = '${__P(' + $propertyKey + '_delay,' + $DelaySeconds + ')}'
    return @"
<ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup" testname="$Name">
  <stringProp name="ThreadGroup.on_sample_error">startnextloop</stringProp>
  <elementProp name="ThreadGroup.main_controller" elementType="LoopController" guiclass="LoopControlPanel" testclass="LoopController" testname="Loop Controller">
    <stringProp name="LoopController.loops">1</stringProp>
    <boolProp name="LoopController.continue_forever">false</boolProp>
  </elementProp>
  <stringProp name="ThreadGroup.num_threads">$threadExpression</stringProp>
  <stringProp name="ThreadGroup.ramp_time">$rampExpression</stringProp>
  <boolProp name="ThreadGroup.scheduler">true</boolProp>
  <stringProp name="ThreadGroup.duration">$durationExpression</stringProp>
  <stringProp name="ThreadGroup.delay">$delayExpression</stringProp>
  <boolProp name="ThreadGroup.same_user_on_next_iteration">true</boolProp>
</ThreadGroup>
<hashTree>
  <CSVDataSet guiclass="TestBeanGUI" testclass="CSVDataSet" testname="Unique virtual-user data">
    <stringProp name="delimiter">,</stringProp>
    <stringProp name="fileEncoding">UTF-8</stringProp>
    <stringProp name="filename">$CsvFile</stringProp>
    <boolProp name="ignoreFirstLine">true</boolProp>
    <boolProp name="quotedData">true</boolProp>
    <boolProp name="recycle">false</boolProp>
    <stringProp name="shareMode">shareMode.all</stringProp>
    <boolProp name="stopThread">true</boolProp>
    <stringProp name="variableNames">name,email,password,searchTerm,quantity,shippingAddress</stringProp>
  </CSVDataSet>
  <hashTree/>
  <HeaderManager guiclass="HeaderPanel" testclass="HeaderManager" testname="HTTP headers">
    <collectionProp name="HeaderManager.headers">
      <elementProp name="Content-Type" elementType="Header">
        <stringProp name="Header.name">Content-Type</stringProp>
        <stringProp name="Header.value">application/json</stringProp>
      </elementProp>
      <elementProp name="Authorization" elementType="Header">
        <stringProp name="Header.name">Authorization</stringProp>
        <stringProp name="Header.value">Bearer `${authToken}</stringProp>
      </elementProp>
    </collectionProp>
  </HeaderManager>
  <hashTree/>
  <LoopController guiclass="LoopControlPanel" testclass="LoopController" testname="Repeat workflow until duration ends">
    <intProp name="LoopController.loops">-1</intProp>
    <boolProp name="LoopController.continue_forever">true</boolProp>
  </LoopController>
  <hashTree>
$workflow
  </hashTree>
</hashTree>
"@
}

function New-ListenerXml {
    param(
        [string]$Name,
        [string]$GuiClass
    )

    return @"
<ResultCollector guiclass="$GuiClass" testclass="ResultCollector" testname="$Name">
  <boolProp name="ResultCollector.error_logging">false</boolProp>
  <objProp name="saveConfig">
    <name>saveConfig</name>
    <value class="SampleSaveConfiguration">
      <time>true</time><latency>true</latency><timestamp>true</timestamp><success>true</success>
      <label>true</label><code>true</code><message>true</message><threadName>true</threadName>
      <dataType>true</dataType><encoding>false</encoding><assertions>true</assertions>
      <subresults>true</subresults><responseData>false</responseData><samplerData>false</samplerData>
      <xml>false</xml><fieldNames>true</fieldNames><responseHeaders>false</responseHeaders>
      <requestHeaders>false</requestHeaders><responseDataOnError>true</responseDataOnError>
      <saveAssertionResultsFailureMessage>true</saveAssertionResultsFailureMessage><assertionsResultsToSave>0</assertionsResultsToSave>
      <bytes>true</bytes><sentBytes>true</sentBytes><url>true</url><threadCounts>true</threadCounts>
      <idleTime>true</idleTime><connectTime>true</connectTime>
    </value>
  </objProp>
  <stringProp name="filename"></stringProp>
</ResultCollector>
<hashTree/>
"@
}

function New-TestPlanXml {
    param(
        [string]$Scenario,
        [string]$ThreadGroupsXml,
        [string]$ListenerName,
        [string]$ListenerGuiClass
    )

    $listener = New-ListenerXml -Name $ListenerName -GuiClass $ListenerGuiClass
    return @"
<?xml version="1.0" encoding="UTF-8"?>
<jmeterTestPlan version="1.2" properties="5.0" jmeter="5.6.3">
  <hashTree>
    <TestPlan guiclass="TestPlanGui" testclass="TestPlan" testname="23127414 $Scenario Performance Test">
      <stringProp name="TestPlan.comments">AI-assisted and human-reviewed E2E performance plan. Run official tests in CLI mode.</stringProp>
      <boolProp name="TestPlan.functional_mode">false</boolProp>
      <boolProp name="TestPlan.tearDown_on_shutdown">true</boolProp>
      <boolProp name="TestPlan.serialize_threadgroups">false</boolProp>
      <elementProp name="TestPlan.user_defined_variables" elementType="Arguments" guiclass="ArgumentsPanel" testclass="Arguments" testname="User Defined Variables">
        <collectionProp name="Arguments.arguments"/>
      </elementProp>
    </TestPlan>
    <hashTree>
      <ConfigTestElement guiclass="HttpDefaultsGui" testclass="ConfigTestElement" testname="HTTP Request Defaults">
        <elementProp name="HTTPsampler.Arguments" elementType="Arguments" guiclass="HTTPArgumentsPanel" testclass="Arguments" testname="User Defined Variables">
          <collectionProp name="Arguments.arguments"/>
        </elementProp>
        <stringProp name="HTTPSampler.domain">`${__P(host,localhost)}</stringProp>
        <stringProp name="HTTPSampler.port">`${__P(port,3000)}</stringProp>
        <stringProp name="HTTPSampler.protocol">http</stringProp>
        <stringProp name="HTTPSampler.contentEncoding">UTF-8</stringProp>
        <stringProp name="HTTPSampler.connect_timeout">5000</stringProp>
        <stringProp name="HTTPSampler.response_timeout">10000</stringProp>
      </ConfigTestElement>
      <hashTree/>
$ThreadGroupsXml
$listener
    </hashTree>
  </hashTree>
</jmeterTestPlan>
"@
}

$loadGroup = New-ThreadGroupXml -Name 'Load — 20 VUs' -Threads 20 -RampSeconds 60 -DurationSeconds 300 -DelaySeconds 0 -CsvFile 'data/users-load.csv' -PropertyPrefix 'load'
$loadPlan = New-TestPlanXml -Scenario 'Load' -ThreadGroupsXml $loadGroup -ListenerName 'Summary Report' -ListenerGuiClass 'SummaryReport'

$stressGroup = New-ThreadGroupXml -Name 'Stress — ramp to 1000 VUs' -Threads 1000 -RampSeconds 300 -DurationSeconds 420 -DelaySeconds 0 -CsvFile 'data/users-stress.csv' -PropertyPrefix 'stress'
$stressPlan = New-TestPlanXml -Scenario 'Stress' -ThreadGroupsXml $stressGroup -ListenerName 'Aggregate Report' -ListenerGuiClass 'StatVisualizer'

$spikeBaseline = New-ThreadGroupXml -Name 'Spike baseline — 10 VUs' -Threads 10 -RampSeconds 10 -DurationSeconds 240 -DelaySeconds 0 -CsvFile 'data/users-spike-baseline.csv' -PropertyPrefix 'spike.baseline'
$spikeBurst = New-ThreadGroupXml -Name 'Spike burst — add 500 VUs' -Threads 500 -RampSeconds 5 -DurationSeconds 60 -DelaySeconds 60 -CsvFile 'data/users-spike-burst.csv' -PropertyPrefix 'spike.burst'
$spikePlan = New-TestPlanXml -Scenario 'Spike' -ThreadGroupsXml ($spikeBaseline + $spikeBurst) -ListenerName 'View Results Tree' -ListenerGuiClass 'ViewResultsFullVisualizer'

$soakGroup = New-ThreadGroupXml -Name 'Soak — 300 sustained VUs' -Threads 300 -RampSeconds 60 -DurationSeconds 900 -DelaySeconds 0 -CsvFile 'data/users-stress.csv' -PropertyPrefix 'soak'
$soakPlan = New-TestPlanXml -Scenario 'Soak' -ThreadGroupsXml $soakGroup -ListenerName 'Simple Data Writer' -ListenerGuiClass 'SimpleDataWriter'

$plans = @{
    Load   = $loadPlan
    Stress = $stressPlan
    Spike  = $spikePlan
    Soak   = $soakPlan
}

foreach ($scenario in $Scenarios) {
    $path = Join-Path $planDirectory "23127414_$($scenario)_$ExecutionDate.jmx"
    [System.IO.File]::WriteAllText($path, $plans[$scenario], [System.Text.UTF8Encoding]::new($false))
    Write-Host "Generated: $path"
}
