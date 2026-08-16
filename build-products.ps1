# ============================================================
# TOPECH static site — product detail page generator
# Generates products/<slug>.html from product data below.
# Run: powershell -ExecutionPolicy Bypass -File build-products.ps1
# ============================================================
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$outDir = Join-Path $root "products"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$utf8 = New-Object System.Text.UTF8Encoding($false)
$siteBase = "https://topechltd.com"

# Escape a string for safe use inside HTML attributes
function HtmlEsc($t) {
  return ($t -replace '&', '&amp;') -replace '<', '&lt;' -replace '>', '&gt;'
}
# Normalize a string for safe embedding in JSON-LD (strip tags, decode entities)
function JsonEsc($t) {
  $s = $t -replace '<[^>]+>', ''
  $s = $s -replace '&lt;', '<' -replace '&gt;', '>' -replace '&quot;', '"' -replace '&#39;', "'" -replace '&nbsp;', ' ' -replace '&amp;', '&'
  return $s.Trim()
}

$whyBuy = @(
  @{ i = "🏭"; h = "Factory-Direct Supply"; p = "Buy straight from the manufacturer. Competitive wholesale pricing for distributors, labs and bulk orders — OEM labeling available." },
  @{ i = "📋"; h = "Standards Compliant"; p = "Designed and tested against ASTM, GB/T, SH/T and ISO methods for reliable, repeatable oil product quality assurance." },
  @{ i = "🚚"; h = "Fast Global Shipping"; p = "Export-grade wooden case packaging with worldwide delivery via air / sea freight. Sample units ship within 3–5 business days." },
  @{ i = "🛠️"; h = "Lifetime Technical Support"; p = "Operation manuals, test videos and remote engineering support for the entire product lifecycle from our technical team." }
)

function Build-Page($d) {
  $specRows = ""
  foreach ($k in $d.specs.Keys) {
    $specRows += "        <tr><th>$k</th><td>$($d.specs[$k])</td></tr>`r`n"
  }
  $appIcons = @("🧪", "🔬", "🏭", "⚙️")
  $appHtml = ""
  for ($i = 0; $i -lt $d.apps.Count; $i++) {
    $a = $d.apps[$i]
    $appHtml += @"
      <div class="feature-item">
        <div class="f-icon">$($appIcons[$i % 4])</div>
        <h4>$($a.h)</h4>
        <p>$($a.p)</p>
      </div>

"@
  }
  $tagsHtml = ""
  foreach ($t in $d.tags) { $tagsHtml += "<span>$t</span>" }
  $thumbHtml = ""
  $n = 0
  foreach ($img in $d.imgs) {
    $cls = if ($n -eq 0) { " class=`"active`"" } else { "" }
    $thumbHtml += "        <button$cls><img src=`"../images/products/$img`" data-full=`"../images/products/$img`" alt=`"$($d.name) image $($n+1)`"></button>`r`n"
    $n++
  }
  $videoHtml = ""
  if ($d.videos) {
    $vidTitle = if ($d.videos.Count -gt 1) { "Test Videos" } else { "Test Video" }
    $videoHtml = "  <div class=`"detail-section`">`r`n    <h2>$vidTitle</h2>`r`n"
    foreach ($v in $d.videos) {
      $videoHtml += @"
    <div class="video-wrap">
      <video controls preload="metadata" poster="../images/products/$($v.poster)">
        <source src="../videos/$($v.src)" type="video/mp4">
        Your browser does not support the video tag.
      </video>
    </div>
    <p class="video-note">$($v.note)</p>

"@
    }
    $videoHtml += "  </div>`r`n"
  }
  $whyHtml = ""
  foreach ($w in $whyBuy) {
    $whyHtml += @"
      <div class="feature-item">
        <div class="f-icon">$($w.i)</div>
        <h4>$($w.h)</h4>
        <p>$($w.p)</p>
      </div>

"@
  }
  $faqItems = @(
    @{ q = "What is the minimum order quantity (MOQ) for the $(JsonEsc $d.name)?"; a = "There is no strict MOQ — single-unit and sample orders are welcome. Distributors and OEM partners receive tiered wholesale pricing for bulk quantities." },
    @{ q = "Does TOPECH support OEM / ODM customization?"; a = "Yes. As a manufacturer, TOPECH offers custom labeling, packaging, voltage configuration (110 V / 220 V) and interface customization for OEM and ODM projects." },
    @{ q = "Can I get a sample or demo video before ordering?"; a = "Yes. Evaluation samples ship within 3–5 business days, and full operation videos of the $(JsonEsc $d.name) are available on request to help you verify performance." },
    @{ q = "What is the lead time and how do you ship worldwide?"; a = "Standard lead time is 1–3 weeks. TOPECH ships globally via DHL, FedEx, UPS and air / sea freight with export packaging and full tracking." },
    @{ q = "What warranty and technical support is included?"; a = "Every unit carries a 12-month warranty plus lifetime technical support — operation manuals, remote assistance and spare parts from our engineering team." }
  )
  $faqHtml = ""
  foreach ($f in $faqItems) {
    $faqHtml += @"
      <div class="faq-item">
        <button class="faq-q">$($f.q)</button>
        <div class="faq-a"><div class="faq-a-inner">$($f.a)</div></div>
      </div>

"@
  }

  $pageUrl = "$siteBase/products/$($d.slug).html"
  $ogImage = "$siteBase/images/products/$($d.imgs[0])"
  $seoName = JsonEsc($d.name)
  $seoDesc = JsonEsc($d.metaDesc)
  $seoCatLabel = JsonEsc($d.catLabel)
  $ogDesc = HtmlEsc($d.metaDesc)
  $ldProduct = @"
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "$seoName",
  "image": ["$ogImage"],
  "description": "$seoDesc",
  "sku": "$($d.slug)",
  "category": "$seoCatLabel",
  "brand": { "@type": "Brand", "name": "TOPECH" },
  "manufacturer": {
    "@type": "Organization",
    "name": "Chongqing TOPECH Instrument Co., Limited",
    "email": "sales@topechltd.com",
    "telephone": "+86-177-8310-7268",
    "url": "https://sccqtp.en.alibaba.com"
  }
}
</script>
"@
  $ldBreadcrumb = @"
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    { "@type": "ListItem", "position": 1, "name": "Home", "item": "$siteBase/index.html" },
    { "@type": "ListItem", "position": 2, "name": "Products", "item": "$siteBase/products.html" },
    { "@type": "ListItem", "position": 3, "name": "$seoCatLabel", "item": "$siteBase/products.html?cat=$($d.cat)" },
    { "@type": "ListItem", "position": 4, "name": "$seoName" }
  ]
}
</script>
"@
  $faqList = ""
  $faqCount = 0
  foreach ($f in $faqItems) {
    if ($faqCount -gt 0) { $faqList += ",`r`n" }
    $faqList += "      { `"@type`": `"Question`", `"name`": `"$($f.q)`", `"acceptedAnswer`": { `"@type`": `"Answer`", `"text`": `"$($f.a)`" } }"
    $faqCount++
  }
  $ldFaq = @"
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
$faqList
  ]
}
</script>
"@

  $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>$($d.seoTitle)</title>
<meta name="description" content="$($d.metaDesc)">
<meta name="keywords" content="$($d.keywords)">
<link rel="canonical" href="$pageUrl">
<meta property="og:type" content="product">
<meta property="og:site_name" content="TOPECH Instrument">
<meta property="og:title" content="$($d.seoTitle)">
<meta property="og:description" content="$ogDesc">
<meta property="og:url" content="$pageUrl">
<meta property="og:image" content="$ogImage">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="$($d.seoTitle)">
<meta name="twitter:description" content="$ogDesc">
<meta name="twitter:image" content="$ogImage">
$ldProduct
$ldBreadcrumb
$ldFaq
<link rel="stylesheet" href="../css/style.css">
<link rel="icon" href="../images/favicon.png">
</head>
<body>

<header class="site-header">
  <div class="container header-inner">
    <a href="../index.html" class="logo">
      <span class="logo-mark">T</span>
      <span>TOPECH<small>PETROLEUM TESTING INSTRUMENTS</small></span>
    </a>
    <button class="nav-toggle" aria-label="Menu">☰</button>
    <nav class="main-nav">
      <ul>
        <li><a href="../index.html">Home</a></li>
        <li><a href="../products.html" class="active">Products</a></li>
        <li><a href="../applications.html">Applications</a></li>
        <li><a href="../resources.html">Resources</a></li>
        <li><a href="../contact.html">Contact</a></li>
      </ul>
    </nav>
  </div>
</header>

<div class="container">
  <div class="breadcrumb-dark" style="padding-top:26px;">
    <a href="../index.html">Home</a> › <a href="../products.html">Products</a> › <a href="../products.html?cat=$($d.cat)">$($d.catLabel)</a> › <strong>$($d.name)</strong>
  </div>

  <div class="detail-top" style="padding-top:0;">
    <div class="detail-gallery">
      <div class="main-img"><img src="../images/products/$($d.imgs[0])" alt="$($d.name)"></div>
      <div class="thumbs">
$thumbHtml      </div>
    </div>
    <div class="detail-info">
      <div class="cat-label">$($d.catLabel)</div>
      <h1>$($d.name)</h1>
      <div class="sub">$($d.sub)</div>
      <div class="desc">$($d.desc)</div>
      <div class="tag-row">$tagsHtml</div>
      <a href="../contact.html" class="btn btn-primary">Send Inquiry</a>
      <a href="../products.html" class="btn btn-dark">All Products</a>
    </div>
  </div>

  <div class="detail-section">
    <h2>Product Specifications</h2>
    <table class="spec-table">
$specRows    </table>
  </div>

$videoHtml

  <div class="detail-section">
    <h2>Application Scenarios</h2>
    <div class="feature-grid">
$appHtml    </div>
  </div>

  <div class="detail-section">
    <h2>Why Buy From TOPECH</h2>
    <div class="feature-grid">
$whyHtml    </div>
  </div>

  <div class="detail-section">
    <h2>Frequently Asked Questions</h2>
$faqHtml
  </div>

  <div class="cta-banner">
    <h2>Looking for a Reliable Oil Testing Equipment Supplier?</h2>
    <p>TOPECH is a China-based manufacturer of petroleum testing instruments and lubricant additives, offering OEM/ODM services, wholesale pricing and global shipping. Contact us for quotations, samples and technical documentation.</p>
    <a href="../contact.html" class="btn btn-primary">Send Inquiry</a>
    <a href="https://wa.me/8617783107268" target="_blank" rel="noopener" class="btn btn-outline">WhatsApp: +86 177 8310 7268</a>
  </div>
</div>

<footer class="site-footer">
  <div class="container">
    <div class="footer-grid">
      <div>
        <div class="footer-logo">TOPECH</div>
        <p>Manufacturer of devices for quality assurance of oil products — petroleum testing instruments, oil friction testers and engine oil additives.</p>
      </div>
      <div>
        <h4>Products</h4>
        <ul>
          <li><a href="../products.html?cat=friction">Oil Friction Testers</a></li>
          <li><a href="../products.html?cat=analysis">Analysis Instruments</a></li>
          <li><a href="../products.html?cat=additive">Lubricant Additives</a></li>
        </ul>
      </div>
      <div>
        <h4>Quick Links</h4>
        <ul>
          <li><a href="../applications.html">Applications</a></li>
          <li><a href="../resources.html">Technical Resources</a></li>
          <li><a href="../contact.html">Contact Us</a></li>
        </ul>
      </div>
      <div>
        <h4>Contact</h4>
        <ul>
          <li>Email: <a href="mailto:sales@topechltd.com">sales@topechltd.com</a></li>
          <li>WhatsApp: <a href="https://wa.me/8617783107268" target="_blank" rel="noopener">+86 177 8310 7268</a></li>
          <li>Web: <a href="https://sccqtp.en.alibaba.com" target="_blank" rel="noopener">sccqtp.en.alibaba.com</a></li>
        </ul>
      </div>
    </div>
    <div class="footer-bottom">© <span id="year">2026</span> TOPECH Instrument. All rights reserved.</div>
  </div>
</footer>

<script src="../js/main.js"></script>
</body>
</html>
"@
  return $html
}

$products = @()

$products += ,@{
  slug = "oil-friction-tester"; cat = "friction"; catLabel = "Oil Friction Testers"
  name = "Portable Oil Friction Tester"
  seoTitle = "Portable Oil Friction Tester, Oil Abrasion Lubricity Tester | TOPECH"
  metaDesc = "TOPECH portable oil friction tester demonstrates lubricant anti-wear performance: ordinary oil locks at 3-4 weights, anti-friction oil runs past 12 weights."
  keywords = "oil friction tester,lubricity tester,oil abrasion tester,oil wear test equipment,anti friction tester"
  sub = "Lubricity / Oil Abrasion Demo Machine · 12 Weights · 220 V"
  desc = "The portable oil friction tester is used for testing the anti-friction and anti-wear performance of lubricating oils and additives. Under 220 V test conditions, ordinary oil locks the machine with 3–4 weights, while anti-friction oil allows more than 12 weights without locking — a dramatic, visual demonstration of lubricant quality. Standard packing includes the machine body, 12 weights, 2 iron oil cups, 2 oil stones, power cable, 30 steel balls, a spare abrasive wheel and a portable air case."
  tags = @("12 Weights", "220 V", "Portable Case", "30 Steel Balls", "Demo Video")
  imgs = @("oil-friction-tester.jpg", "oil-friction-tester-front.jpg", "oil-friction-tester-panel.jpg", "oil-friction-tester-weights.jpg", "oil-friction-tester-case.jpg", "oil-friction-tester-case-2.jpg", "oil-friction-tester-case-3.jpg")
    videos = @( @{ src = "anti-wear-test.mp4"; poster = "oil-friction-tester-panel.jpg"; note = "Watch the Portable Oil Friction Tester running a real anti-wear test — live friction readings, weight loading and wear comparison in one demonstration." } )
  specs = [ordered]@{
    "Model" = "Portable Oil Friction Tester (Lubricity Tester)"
    "Test Voltage" = "AC 220 V"
    "Weights" = "12 pcs, each ≈ 100 kg load on the friction pair"
    "Ordinary Oil Lock-Up" = "3–4 weights"
    "Anti-Friction Oil" = "More than 12 weights without lock-up"
    "Oil Cup" = "Iron oil cup × 2 (never leak, never deform)"
    "Steel Balls" = "30 pcs standard"
    "Accessories" = "2 oil stones, spare abrasive wheel, power cable"
    "Package" = "Portable aluminum air case"
  }
  apps = @(
    @{ h = "Lubricant Showroom Demonstration"; p = "Show customers the difference between ordinary and anti-wear oil live — weights, current and noise tell the story instantly." },
    @{ h = "Additive Promotion &amp; Sales"; p = "Ideal demonstration tool for engine oil additive distributors to prove product effect at auto markets and exhibitions." },
    @{ h = "Training &amp; Education"; p = "Used by technical schools and lubricant training courses to teach boundary lubrication and anti-wear principles." },
    @{ h = "Incoming Oil Quality Check"; p = "Quick comparative screening of lubricant batches against a reference oil before purchase or use." }
  )
}

$products += ,@{
  slug = "digital-anti-wear-tester"; cat = "friction"; catLabel = "Oil Friction Testers"
  name = "Anti-Wear Tester with Five-Digit Display"
  seoTitle = "New Anti-Wear Tester with Five-Digit Display | TOPECH"
  metaDesc = "TOPECH anti-wear tester with five digital displays shows voltage, current, instantaneous power, power consumption and oil temperature during friction tests."
  keywords = "anti wear tester,oil friction tester with display,power consumption tester,oil temperature tester"
  sub = "Displays V · A · W · kWh · Oil Temperature in Real Time"
  desc = "The new generation anti-wear tester adds five digital displays showing voltage (V), current (A), instantaneous power (W), power consumption (kWh) and instantaneous oil temperature (T). Run two machines side by side for a strictly fair comparison: place the same weights, run 3–5 minutes, and observe current, power and temperature differences. Lower oil temperature means better viscosity stability; lower power consumption means better fuel economy; stable color and no smoke indicate superior lubricant quality."
  tags = @("5 Digital Displays", "Side-by-Side Comparison", "Real-Time Temperature", "220 V")
  imgs = @("digital-anti-wear-tester-silver.jpg", "digital-anti-wear-tester-angle.jpg", "digital-anti-wear-tester-display.jpg", "digital-anti-wear-tester-grey.jpg", "digital-anti-wear-tester.jpg", "digital-anti-wear-tester-set.jpg", "digital-anti-wear-tester-unit.jpg", "digital-anti-wear-tester-panel.jpg")
    videos = @(
        @{ src = "anti-wear-test.mp4"; poster = "digital-anti-wear-tester-silver.jpg"; note = "Watch the Anti-Wear Tester with Five-Digit Display running a real anti-wear test — live V / A / W readings, weight loading and wear comparison in one demonstration." },
        @{ src = "anti-water-test.mp4"; poster = "digital-anti-wear-tester-display.jpg"; note = "Anti-water test demonstration on the Anti-Wear Tester with Five-Digit Display — real-time performance under water exposure." }
      )
  specs = [ordered]@{
    "Model" = "Anti-Wear Tester with Five-Digit Display"
    "Display Items" = "Voltage (V), Current (A), Power (W), Consumption (kWh), Oil temperature (T)"
    "Test Voltage" = "AC 220 V"
    "Comparison Mode" = "Two machines side by side, simultaneous start"
    "Test Duration" = "3–5 minutes per comparative run"
    "Load" = "Adjustable weights on long lever"
    "Observation Items" = "Temperature, current, power, consumption, color &amp; smoke"
  }
  apps = @(
    @{ h = "Quantified Oil Comparison"; p = "Numbers instead of feelings — prove lubricant quality with measured current, power and temperature data." },
    @{ h = "Distributor Roadshows"; p = "Dual-machine live comparison creates a strong, credible sales scene for lubricant brands." },
    @{ h = "Fuel Economy Education"; p = "Demonstrate how lower friction power consumption translates into fuel saving for end users." },
    @{ h = "Lab Teaching"; p = "Five readable parameters make it an excellent instrument for tribology and lubrication classes." }
  )
}

$products += ,@{
  slug = "high-temp-engine-oil-tester"; cat = "friction"; catLabel = "Oil Friction Testers"
  name = "High Temperature Engine Oil Testing Machine"
  seoTitle = "High Temperature Engine Oil Testing Machine | TOPECH"
  metaDesc = "High temperature engine oil testing machine evaluates carbon deposit, viscosity, boiling point, oxidation resistance and acidity of lubricants at heat."
  keywords = "high temperature oil tester,engine oil testing machine,oil carbon deposit test,oil oxidation test"
  sub = "Carbon Deposit · Viscosity · Boiling Point · Oxidation · Acidity at High Temperature"
  desc = "The high temperature engine oil testing machine heats lubricant samples in test tubes to evaluate carbon deposit, viscosity, boiling point, oxidation resistance and acidity. Two temperature meters work together: the left meter sets and shows the instrument temperature, while the right meter shows the instantaneous temperature of the oil in the test tube. A copper rod immersed in the oil reveals acidity — discoloration of the copper rod at high temperature indicates acidic, poor-quality oil. Wear insulation gloves throughout the experiment."
  tags = @("High Temperature", "Dual Thermometers", "Copper Rod Acidity Test", "Test Tube Method")
  imgs = @("high-temp-engine-oil-tester.jpg", "high-temp-oil-test-tube.jpg", "high-temp-oil-test-result.jpg")
  specs = [ordered]@{
    "Model" = "High Temperature Engine Oil Testing Machine"
    "Test Items" = "Carbon deposit, viscosity, boiling point, oxidation resistance, acidity"
    "Temperature Control" = "Left meter: set / instrument temperature; Right meter: instantaneous oil temperature"
    "Sample Container" = "Glass test tube, oil depth ≈ 2/3 of tube"
    "Acidity Indicator" = "Copper rod discoloration observation"
    "Heating" = "Electric heating with adjustable set temperature"
    "Safety" = "Insulation gloves required during operation"
  }
  apps = @(
    @{ h = "Engine Oil Quality Screening"; p = "Spot poor lubricants quickly by observing boiling point, color change and carbon deposit tendency under heat." },
    @{ h = "Oxidation Resistance Evaluation"; p = "Record the time and temperature at which oil discolors to compare oxidation stability between brands." },
    @{ h = "Acidity Detection"; p = "Copper rod discoloration reveals acidic oils that accelerate engine corrosion." },
    @{ h = "Counterfeit Oil Identification"; p = "Low boiling point, fast blackening and strong odor expose counterfeit or recycled engine oils." }
  )
}

$products += ,@{
  slug = "flash-point-tester"; cat = "analysis"; catLabel = "Analysis Instruments"
  name = "Fully Automatic Open / Closed Cup Flash Point Tester"
  seoTitle = "Fully Automatic Open Cup / Closed Cup Flash Point Test Apparatus | TOPECH"
  metaDesc = "Automatic flash point analyzer to ASTM D92 / D93 with color touch screen, electronic ignition, automatic atmospheric pressure correction and self-checking."
  keywords = "ASTM D92,ASTM D93,Flash point apparatus,Pensky Martens,flash point tester"
  sub = "ASTM D92 / ASTM D93 · Electronic Ignition · Touch Screen · No Gas Source Needed"
  desc = "The automatic flash point analyzer (open cup / closed cup) is designed in accordance with ASTM D92 / ASTM D93, ISO 2592, GB 267, GB 3536 and equivalent standards. Microcomputer technology makes stirring, ignition, testing, alerting, cooling and printing completely automatic. A built-in atmospheric pressure detector automatically corrects the flash point result, while the security airless platinum-alloy igniter removes the need for any gas source. Ideal for petroleum, chemical, power station, environmental, railway and scientific research laboratories."
  tags = @("ASTM D92 / D93", "No Gas Source", "Touch Screen", "Auto Pressure Correction", "300 Data Groups")
  imgs = @("flash-point-tester.jpg")
  specs = [ordered]@{
    "Standards" = "ASTM D92 / ASTM D93, ISO 2592, GB 267, GB 3536"
    "Ignition" = "Electronic, platinum alloy — no gas source required"
    "Display" = "Color touch screen, English man-machine interface"
    "Atmospheric Correction" = "Built-in detector, automatic flash point correction"
    "Data Storage" = "300 groups of testing data"
    "Automation" = "Stirring, ignition, testing, alerting, cooling, printing fully automatic"
    "Control" = "Adaptive PID heating algorithm per standard curves"
    "Safety" = "Over-temperature detection with automatic stop and alert"
    "Printer" = "High-speed thermal printer"
    "Self-Checking" = "Breakdown self-diagnosis function"
  }
  apps = @(
    @{ h = "Refinery Quality Control"; p = "Routine flash point determination of fuels, solvents and lubricants in refinery QC laboratories." },
    @{ h = "Power Plant Oil Monitoring"; p = "Detect light-end contamination in transformer and turbine oils through flash point drop." },
    @{ h = "Transport &amp; Storage Safety"; p = "Classify flammability of chemicals for safe handling, transport and storage regulations." },
    @{ h = "Research &amp; Formulation"; p = "Evaluate batch consistency and formulation changes with precise, repeatable flash point data." }
  )
}

$products += ,@{
  slug = "kinematic-viscosity-tester-lyv8"; cat = "analysis"; catLabel = "Analysis Instruments"
  name = "LYV-8 Digital Kinematic Viscosity Tester"
  seoTitle = "LYV-8 Digital Kinematic Viscosity Tester, ASTM D445 | TOPECH"
  metaDesc = "LYV-8 kinematic viscosity tester to ASTM D445 with precise digital temperature control, 4 viscometer positions and uniform homeothermic water bath."
  keywords = "ASTM D445,Digital Kinematic Viscosity Tester,IP71,viscosity meter,viscosity test plant"
  sub = "GB 265 / ASTM D445 / IP 71 · ±0.1 °C · 4 Viscometers Simultaneously"
  desc = "The LYV-8 kinematic viscosity tester is applicable to GB 265-88, GB 1814, ASTM D445, IP 71 and other determining methods. A precise imported digital temperature controller keeps the ten-liter homeothermic water bath uniform, while a highlighted digital stopwatch times flow with ±0.1 s accuracy. Four viscometer installing holes allow testing four oil samples simultaneously; the instrument can also serve as a high-viscosity homeothermic water bath for other tests."
  tags = @("ASTM D445", "±0.1 °C", "±0.1 s", "4 Positions", "10 L Bath")
  imgs = @("kinematic-viscosity-tester-lyv8.jpg")
  specs = [ordered]@{
    "Standards" = "GB 265-88, GB 1814, ASTM D445, IP 71"
    "Capillary Viscometer" = "Per SH/T 0173-92 and JJG 155 regulations"
    "Display" = "Precise digital temperature controller + highlighted digital stopwatch"
    "Temperature Control Range" = "Room temperature to 150 °C, arbitrary setting"
    "Testing Range" = "Kinematic viscosity 0.5–20000 mm²/s; dynamic 0.3–40000 mPa·s"
    "Temperature Accuracy" = "±0.1 °C"
    "Timing Accuracy / Range" = "±0.1 s; 0.1 s – 999.9 s"
    "Homoeothermic Bath" = "300 × 300 mm double layer, 10 L"
    "Stirring Speed" = "1520 rounds/min"
    "Max Power" = "1800 W"
    "Sample Positions" = "4 pieces simultaneously"
    "Power Supply" = "AC 220 V ±10%, 50 Hz ±1 Hz"
    "Dimensions" = "220 × 190 × 500 mm (L × W × H)"
    "Weight" = "12 kg"
  }
  apps = @(
    @{ h = "Lubricant QC Labs"; p = "Routine kinematic viscosity measurement of engine oils, gear oils and hydraulic fluids at 40 °C / 100 °C." },
    @{ h = "Refinery Blending Control"; p = "Verify blend batches against viscosity grade specifications before release." },
    @{ h = "Used Oil Analysis"; p = "Track viscosity change in service to judge oxidation, dilution and oil drain intervals." },
    @{ h = "Teaching &amp; Calibration"; p = "Four parallel positions and clear digital readout suit training labs and method comparison." }
  )
}

$products += ,@{
  slug = "kinematic-viscosity-tester-ly445"; cat = "analysis"; catLabel = "Analysis Instruments"
  name = "LY-445 ASTM Kinematic Viscosity Tester"
  seoTitle = "LY-445 ASTM Kinematic Viscosity Tester, Automatic | TOPECH"
  metaDesc = "LY-445 automatic kinematic viscosity tester with SCM control, color LCD, auto timing, calculation and printing — high and low viscosity oils supported."
  keywords = "ASTM D445,kinematic viscosity apparatus,viscosity meter,viscosity tester"
  sub = "SCM Control · Color LCD · Auto Timing, Calculation &amp; Printing"
  desc = "The LY-445 viscosity tester works under GB 265-88, GB 1814, ASTM D445, IP 71 and other standards. Advanced SCM control with a large color LCD screen guides operation with menu tips in English. Unique modular technology tests both high-viscosity and low-viscosity oils, while four viscometer positions run samples simultaneously. The instrument automatically calculates kinematic viscosity values and averages, then prints and stores the results."
  tags = @("ASTM D445", "Auto Calculation", "Color LCD", "High &amp; Low Viscosity")
  imgs = @("kinematic-viscosity-tester-ly445.jpg")
  specs = [ordered]@{
    "Standards" = "GB 265-88, GB 1814, ASTM D445, IP 71"
    "Control" = "Advanced SCM, intelligent temperature control"
    "Display" = "Large color LCD with English operation menu"
    "Viscosity Coverage" = "High-viscosity and low-viscosity oils (modular technology)"
    "Sample Positions" = "4 viscometers simultaneously"
    "Bath" = "10 L homeothermic bathtub with organic glass stay-warm case"
    "Heater" = "Stainless steel, anti-corrosion; ring-type daylight lamp for observation"
    "Viscometer Clamp" = "Three-point vertical type, reliable grasp"
    "Automation" = "Auto timing, calculation, average, printing and storage"
    "Status Indication" = "Regular display of temperature, time and parameters"
  }
  apps = @(
    @{ h = "Full-Range Viscosity Testing"; p = "One instrument covers light fuels to heavy gear oils thanks to modular high / low viscosity design." },
    @{ h = "Report-Ready QC"; p = "Automatic calculation, printing and memory deliver traceable viscosity records for audits." },
    @{ h = "Batch Consistency Checks"; p = "Four simultaneous positions speed up comparison of production batches." },
    @{ h = "Lubricant Labs &amp; Institutes"; p = "Standard-compliant results for certification bodies and third-party inspection." }
  )
}

$products += ,@{
  slug = "pour-point-tester"; cat = "analysis"; catLabel = "Analysis Instruments"
  name = "Petroleum Pour Point &amp; Cloud Point Tester"
  seoTitle = "Petroleum Pour Point Tester, Pour Point Apparatus ASTM | TOPECH"
  metaDesc = "Petroleum pour point and cloud point tester to GB/T 510 and GB/T 3535 with cascade refrigeration, metal bath cooling and double-aperture design."
  keywords = "Petroleum pour point tester,pour point apparatus,pour point astm,cloud point tester"
  sub = "GB/T 510 · GB/T 3535 · Cascade Refrigeration · No Alcohol Needed"
  desc = "Pour point is the lowest temperature at which an inclined oil sample starts to move; cloud point is the highest temperature at which cooled oil stops moving — both measure low-temperature fluidity. This determinator follows GB/T 510 and GB/T 3535 and is mainly used for transformer oil, lubricating oil and similar products. Embedded temperature control with LCD display, cascade refrigeration and metal-bath cooling deliver fast, stable cooling without alcohol or other cooling media. The double-aperture design tests pour point, condensation point, cloud point and cold filtration point without mutual interference."
  tags = @("GB/T 510", "GB/T 3535", "Cascade Cooling", "Double Aperture", "±0.1 °C")
  imgs = @("pour-point-tester.jpg")
  specs = [ordered]@{
    "Standards" = "GB/T 510, GB/T 3535"
    "Control" = "Embedded system temperature control, LCD display"
    "Refrigeration" = "Cascade refrigeration, fast cooling speed"
    "Cooling Method" = "Metal bath cooling — no alcohol or cooling medium needed"
    "Temperature Precision" = "±0.1 °C"
    "Cooling Time" = "≤ 20 min"
    "Cold Bath Size" = "200 × 90 × 90 mm"
    "Tilting" = "45° bath tilt support with timing display"
    "Apertures" = "Double aperture — pour, cloud, condensation &amp; cold filtration points"
    "Input Power" = "&lt; 1800 W"
    "Power Supply" = "AC 220 V ±10%, 50 Hz"
  }
  apps = @(
    @{ h = "Winter-Grade Oil Development"; p = "Qualify low-temperature fluidity of engine and gear oils for cold-climate grades." },
    @{ h = "Transformer Oil Acceptance"; p = "Confirm pour point of insulating oils for substation use in cold regions." },
    @{ h = "Fuel Cold Flow Testing"; p = "Cloud point and cold filtration assessment of diesel and similar fuels." },
    @{ h = "Storage &amp; Transport Planning"; p = "Ensure oils remain pumpable through pipelines and tanks in winter." }
  )
}

$products += ,@{
  slug = "oil-acidity-analyzer"; cat = "analysis"; catLabel = "Analysis Instruments"
  name = "Fully Automatic Oil Acidity Analyzer"
  seoTitle = "Fully Automatic Oil Acidity Analyzer / Acid Value Tester | TOPECH"
  metaDesc = "Automatic acid value tester to ASTM D974 for transformer oil, turbine oil and motor oil — 6 sample cups, color LCD, 0.0001 mgKOH/g resolution."
  keywords = "acid value tester,oil acidity analyzer,acid number test plant,ASTM D974,Turbine Oil"
  sub = "ASTM D974 · GB/T 264 · 6 Sample Cups · 0.0001 mgKOH/g Resolution"
  desc = "This acidity analyzer applies the acid-base titration principle under micro-computer control with color LCD display and English input menu, conforming to ASTM D974, GB/T 264, GB 7599-87 and GB/T 7304-2000. It accurately tests the acid value of transformer oil, steam-turbine oil, fire-resistant oil, diesel and gasoline oils, and is widely used in chemical industry, power and petroleum fields. Automatic liquid adding, titration, stirring, end-point judgment, pipe cleaning and result printing make the whole process hands-free."
  tags = @("ASTM D974", "6 Cups Parallel", "Auto Titration", "260 Data Groups")
  imgs = @("oil-acidity-analyzer.jpg")
  specs = [ordered]@{
    "Standards" = "ASTM D974, GB/T 264, GB 7599-87, GB/T 7304-2000"
    "Display" = "7-inch color LCD, English menu"
    "Testing Range" = "0.0005–0.5000 mgKOH/g"
    "Resolution" = "0.0001 mgKOH/g"
    "Accuracy" = "0.001–0.100 mgKOH/g: deviation 0.0005 mgKOH/g; 0.1–0.5 mgKOH/g: 5% of indication"
    "Repeatability" = "0.004 mgKOH/g"
    "Sample Cups" = "6 cups with automatic change-over for parallel comparison"
    "Automation" = "Liquid adding, titration, stirring, end-point judgment, cleaning, printing"
    "Data Storage" = "260 groups"
    "Printing" = "High-speed thermal dot printing"
    "Power Supply" = "220 V ±10%, 50 Hz ±5%; humidity ≤ 85%"
    "Dimensions / Weight" = "440 × 300 × 220 mm / 16 kg"
  }
  apps = @(
    @{ h = "Power Plant Oil Monitoring"; p = "Track acid value of transformer and turbine oil to schedule reconditioning before corrosion starts." },
    @{ h = "Refinery Product Release"; p = "Verify acidity of finished fuels and lubricants meets specification limits." },
    @{ h = "Used Oil Condition Assessment"; p = "Rising acid number signals oxidation and additive depletion in service oils." },
    @{ h = "Third-Party Testing Labs"; p = "Six parallel cups and automatic records suit high-throughput certified laboratories." }
  )
}

$products += ,@{
  slug = "karl-fischer-water-content-tester"; cat = "analysis"; catLabel = "Analysis Instruments"
  name = "LY-2100 Fully Automatic Karl Fischer Water Content Tester"
  seoTitle = "LY-2100 Fully Automatic Karl Fischer Water Content Tester | TOPECH"
  metaDesc = "Karl Fischer coulometric moisture tester with 1 ppm to 100% range, 7-inch touch LCD, closed titration system and result display within 60 seconds."
  keywords = "Insulation Oil,moisture meter,moisture tester,Transformer Oil,Turbine Oil,Karl Fischer"
  sub = "Coulometric Method · 1 ppm – 100% · Result in 60 s · 7-Inch Touch LCD"
  desc = "The LY-2100 adopts the globally recognized Karl Fischer coulometric method — the most accurate moisture testing method at low cost. It quickly analyzes water content in liquids, solids and gases from 0.0001% (1 ppm) to 100%, with auto-stirring and analysis completed within 60 seconds. The fully closed titration system protects operators from reagent, and one 500 ml Karl Fischer reagent bottle supports about 1000 consecutive tests. Widely used across petroleum, chemical, power, pharmaceutical, pesticide and research institutions."
  tags = @("Karl Fischer", "1 ppm Sensitivity", "60 s Analysis", "Closed System")
  imgs = @("karl-fischer-water-content-tester.png")
  specs = [ordered]@{
    "Testing Method" = "MPU-controlled electrolysis — Karl Fischer Coulometric Method"
    "Display" = "7-inch color touch LCD, English"
    "Water Content Range" = "0.0001% (1 ppm) – 100%"
    "Testing Range" = "0.01 µg H₂O – 200 mg H₂O"
    "Sensitivity" = "0.01 µg H₂O"
    "Electrolysis Rate" = "2.4 mg H₂O/min; current auto-controlled within 430 mA"
    "Accuracy" = "2–100 µg: ≤ ±1 µg; 100–1000 µg: ≤ ±2.9 µg; &gt; 1000 µg: ≤ ±0.2%"
    "Analysis Time" = "Auto stirring + analysis within 60 s"
    "Reagent" = "500 ml Karl Fischer reagent ≈ 1000 tests"
    "Printing" = "Thermal printer — µg / ppm / mg/L / sample no. / date"
    "Interface" = "USB / RS232 for laptop or PC network management"
    "Power / Consumption" = "AC 220 V ±10%, 50 Hz; &lt; 40 W"
    "Dimensions / Weight" = "390 × 270 × 190 mm / ≈ 7 kg"
  }
  apps = @(
    @{ h = "Transformer Oil Moisture"; p = "Keep insulation oil dry — ppm-level water content directly affects dielectric strength." },
    @{ h = "Chemical &amp; Pharmaceutical QC"; p = "Moisture determination of alcohols, esters, solvents, medicine materials and electrolytes." },
    @{ h = "Gas Moisture Analysis"; p = "Natural gas, liquefied gas, Freon and butadiene water content measurement." },
    @{ h = "Food &amp; Industrial Solids"; p = "Mineral salts, citric acid, paraffin and other soluble solids moisture testing." }
  )
}

$products += ,@{
  slug = "petroleum-density-tester"; cat = "analysis"; catLabel = "Analysis Instruments"
  name = "LY-018A Petroleum Products Density Tester"
  seoTitle = "LY-018A Petroleum Products Density Tester, GB/T 1884 | TOPECH"
  metaDesc = "Petroleum products density tester to GB/T 1884-2000 densimeter method with explosion-proof glass bath, intelligent LCD temperature control and 2 test holes."
  keywords = "crude oil density test,density test of oil,oil density test method,oil density tester,Petroleum Products Density Tester"
  sub = "GB/T 1884-2000 · Densimeter Method · LCD Temperature Control · 2 Holes"
  desc = "The LY-018A density tester is designed and made per national standard GB/T 1884-2000 (Test Methods for Density of Petroleum and Liquid Petroleum Products, Densimeter Method). The constant-temperature bath uses rigid insulation explosion-proof glass for easy observation, with convenient measuring-cylinder and thermometer brackets. An intelligent temperature controller with LCD provides rapid, stable temperature control from room temperature to 100 °C."
  tags = @("GB/T 1884", "±0.1 °C", "Explosion-Proof Glass Bath", "2 Holes")
  imgs = @("petroleum-density-tester.jpg")
  specs = [ordered]@{
    "Standard" = "GB/T 1884-2000 (Densimeter method)"
    "Heating Power" = "1800 W"
    "Temperature Range" = "Room temperature to 100 °C"
    "Temperature Precision" = "±0.1 °C"
    "Test Holes" = "2 holes"
    "Bath" = "Rigid insulation explosion-proof glass bowl"
    "Power Supply" = "AC 220 V ±10%, 50 Hz"
    "Environment" = "5–40 °C, relative humidity ≤ 85%"
    "Dimensions" = "560 × 380 × 580 mm (L × W × H)"
  }
  apps = @(
    @{ h = "Crude &amp; Refined Oil Density"; p = "Routine density determination of liquid petroleum products for trade and QC." },
    @{ h = "API Gravity Conversion"; p = "Accurate density at reference temperature supports volume-to-mass oil accounting." },
    @{ h = "Blend Verification"; p = "Detect off-spec blending through density deviation." },
    @{ h = "Lab Teaching"; p = "Clear glass bath and simple densimeter method suit training laboratories." }
  )
}

$products += ,@{
  slug = "oil-color-chroma-tester"; cat = "analysis"; catLabel = "Analysis Instruments"
  name = "LY-225 Petroleum Products Oil Color Chroma Tester"
  seoTitle = "LY-225 Petroleum Products Oil Color Chroma Tester, ASTM D1500 | TOPECH"
  metaDesc = "Oil color chroma tester to ASTM D1500 / SH/T 0168 with standard color wheel, 2750 K light source and eyepiece comparison for lubricants and fuels."
  keywords = "ASTM D1500,oil Chroma analyzer,oil color tester,test instrument"
  sub = "ASTM D1500 · SH/T 0168 · Standard Color Wheel · 2750 K Light Source"
  desc = "The LY-225 chroma tester is manufactured under ASTM D1500 and SH/T 0168 for determining the color of lubricants, kerosene, diesel and other petroleum products, corresponding to GB/T 6540 color numbers. Light from a 220 V / 100 W frosted bulb (2750 ± 50 K) passes milky and sunlight-filter glass to simulate north light, then forms two identical parallel beams through standard color glass and the sample tube. The operator compares sample color (left half of eyepiece) with the 25-grade standard color wheel (right half)."
  tags = @("ASTM D1500", "SH/T 0168", "25-Grade Color Wheel", "North Light Simulation")
  imgs = @("oil-color-chroma-tester.png", "oil-color-wheel.png")
  specs = [ordered]@{
    "Standards" = "ASTM D1500, SH/T 0168 (corresponds to GB/T 6540)"
    "Color Wheel" = "26 × Φ14 holes: 25 graded color glasses + 1 blank"
    "Light Source" = "Inside frosted bulb 220 V / 100 W, 2750 ± 50 K"
    "Optical System" = "Milky glass + sunlight filter to simulate north light"
    "Beams" = "Two parallel beams — sample and standard, identical size and shape"
    "Eyepiece" = "Optical lens with focus and light adjustment; sample left / standard right"
    "Colorimetric Tube" = "Flat glass tube, ID Φ32 mm, height 120–130 mm, colorless"
  }
  apps = @(
    @{ h = "Base Oil Grading"; p = "Color is a fast indicator of refining depth and base oil quality." },
    @{ h = "Fuel Appearance QC"; p = "Check kerosene and diesel color against specification limits." },
    @{ h = "Aging &amp; Contamination Clues"; p = "Darkening lubricant color hints at oxidation or contamination in service." },
    @{ h = "Batch Consistency"; p = "Compare production batch color to reference standards before shipment." }
  )
}

$products += ,@{
  slug = "copper-strip-corrosion-tester"; cat = "analysis"; catLabel = "Analysis Instruments"
  name = "ASTM D130 Copper Strip Corrosion Test Machine"
  seoTitle = "ASTM D130 Copper Strip Corrosion Test Machine | TOPECH"
  metaDesc = "Copper strip corrosion tester to ASTM D130 / GB/T 5096 for aviation gasoline, jet fuel, kerosene, diesel and lubricants corrosion assessment."
  keywords = "ASTM D130,Copper corrosion tester,copper strip corrosion test equipment,copper corrosion analyzer"
  sub = "ASTM D130 · GB/T 5096 · Fuels &amp; Lubricants Corrosion Assessment"
  desc = "This copper strip corrosion test machine complies with GB/T 5096 and ASTM D130, applicable to assessing the corrosion degree of aviation gasoline, jet fuel, motor gasoline, kerosene, diesel, natural gasoline, lubricants and other petroleum products on copper. Polished copper strips are immersed in the sample under controlled temperature, then compared against the ASTM copper strip corrosion classification standards to rate corrosiveness."
  tags = @("ASTM D130", "GB/T 5096", "Fuels &amp; Lubricants", "Standard Rating")
  imgs = @("copper-strip-corrosion-tester.png")
  specs = [ordered]@{
    "Standards" = "ASTM D130, GB/T 5096"
    "Applicable Samples" = "Aviation gasoline, jet fuel, motor gasoline, kerosene, diesel, natural gasoline, lubricants"
    "Test Principle" = "Polished copper strip immersion at controlled temperature, then color comparison"
    "Rating" = "ASTM copper strip corrosion classification (1a – 4c)"
    "Temperature Control" = "Intelligent control for water bath / test bomb conditions"
    "Application" = "Corrosiveness quality control of petroleum products"
  }
  apps = @(
    @{ h = "Jet Fuel Certification"; p = "Copper corrosion rating is mandatory for aviation turbine fuel specification release." },
    @{ h = "Gasoline &amp; Diesel QC"; p = "Detect corrosive sulfur compounds that attack fuel system components." },
    @{ h = "Lubricant Specification"; p = "Verify corrosion protection of oils against copper alloys." },
    @{ h = "Refinery Process Monitoring"; p = "Track corrosiveness through treating units such as sweetening and hydrotreating." }
  )
}

$products += ,@{
  slug = "copper-strip-corrosion-bath-lpg"; cat = "analysis"; catLabel = "Analysis Instruments"
  name = "LY-172 Copper Strip Corrosion Bath for LPG"
  seoTitle = "LY-172 Copper Strip Corrosion Test for LPG / Corrosion Bath | TOPECH"
  metaDesc = "Copper strip corrosion bath for LPG per SH/T 0232 — room temperature to 90 °C, ±0.1 °C precision, microprocessor control with buzzer alarm."
  keywords = "Copper corrosion tester,copper strip corrosion bath,copper strip corrosion test for LPG,SH/T0232"
  sub = "SH/T 0232 · Room Temp to 90 °C · ±0.1 °C · Microprocessor Control"
  desc = "The LY-172 conforms to SH/T 0232 and evaluates the copper corrosion degree of liquefied petroleum gas (LPG). Temperature is freely settable from room temperature to 90 °C with ±0.1 °C precision and a default control point at 40 °C. The bath body is made of imported ground matte stainless steel. The microprocessor-based intelligent controller handles temperature regulation, automatic stop-and-heat test sequencing, and provides flash and buzzer hints."
  tags = @("SH/T 0232", "LPG", "±0.1 °C", "Stainless Steel Bath")
  imgs = @("copper-strip-corrosion-bath-lpg.jpg")
  specs = [ordered]@{
    "Standard" = "SH/T 0232 (copper corrosion test for LPG)"
    "Temperature Range" = "Room temperature to 90 °C, arbitrary setting"
    "Precision" = "±0.1 °C"
    "Default Control Point" = "40 °C"
    "Bath Material" = "Ground matte stainless steel (imported)"
    "Control" = "Microprocessor intelligent temperature control; auto stop rotation &amp; heating test"
    "Hints" = "Flash and buzzer indication"
    "Power Supply" = "AC 220 V + 20 V, 50 Hz"
    "Dimensions / Weight" = "500 × 400 × 600 mm / 15 kg"
  }
  apps = @(
    @{ h = "LPG Station Quality Control"; p = "Verify corrosiveness of liquefied petroleum gas before distribution." },
    @{ h = "Gas Plant Labs"; p = "Routine SH/T 0232 compliance testing in refineries and LPG filling plants." },
    @{ h = "Third-Party Inspection"; p = "Standardized bath conditions for certified corrosion grading reports." },
    @{ h = "Corrosion Research"; p = "Study the effect of sulfur species on copper at controlled temperatures." }
  )
}

$products += ,@{
  slug = "nano-graphene-additive"; cat = "additive"; catLabel = "Lubricant Additives"
  name = "Nano Graphene Lubricant Additive"
  seoTitle = "Nano Graphene Lubricant Additive, Anti-Wear Anti-Friction | TOPECH"
  metaDesc = "Nano graphene additive for engine oil, wind power oil and grease — good oil solubility, anti-wear, anti-friction, anti-oxidation, recommended 3% dosage."
  keywords = "Nano Graphene additive,Graphene additive,lubricant additive,anti wear additive"
  sub = "Engine Oil · Wind Power Oil · Grease · Recommended Dosage 3%"
  desc = "The nano graphene additive is used in engine oil, wind power oil, mechanical oil, emulsion, drilling fluid and grease extreme-pressure lubricants. It has good oil solubility (I, II, III class base oils and PAO) with excellent dispersity, delivering anti-wear, anti-friction and anti-oxidation effects plus increased torque grade. Added to engine oil it also helps repairing, energy saving and relieving oil burning."
  tags = @("3% Dosage", "PAO Soluble", "Anti-Wear", "Anti-Oxidation")
  imgs = @("nano-graphene-additive.jpg", "nano-graphene-additive-2.jpg", "nano-graphene-additive-3.jpg")
  specs = [ordered]@{
    "Appearance" = "Brown green"
    "Viscosity 40 °C" = "33.5 mm²/s"
    "Viscosity 100 °C" = "7.0 mm²/s"
    "Flash Point" = "200 °C"
    "Pour Point" = "-24 °C"
    "PB (3%)" = "120 kg"
    "Long-Term Grinding D (40 kg, 60 min)" = "0.37 mm"
    "Recommended Dosage" = "3%"
    "Solubility" = "Class I / II / III base oils and PAO"
    "Packing" = "100 ml bottle; net 25 kg or 200 kg drums"
    "Storage" = "Per SH 0164; max 75 °C handling, 45 °C long-term storage"
  }
  apps = @(
    @{ h = "Engine Oil Formulation"; p = "Boost anti-wear and fuel-economy performance of passenger car motor oils." },
    @{ h = "Wind Turbine Gear Oil"; p = "Protect heavily loaded wind power gearboxes against micropitting and wear." },
    @{ h = "Grease &amp; Drilling Fluid"; p = "Extreme-pressure lubrication upgrade for greases and drilling muds." },
    @{ h = "Repair-Type Aftermarket"; p = "Self-repairing and oil-burning relief effects support aftermarket treatment products." }
  )
}

$products += ,@{
  slug = "organic-fullerene-additive"; cat = "additive"; catLabel = "Lubricant Additives"
  name = "Anti Friction Organic Fullerene Additive"
  seoTitle = "TOPECH Anti Friction Organic Fullerene Additive | TOPECH"
  metaDesc = "Organic fullerene (modified C60 with N-Mo) anti-friction additive — friction coefficient about 0.02, wear spot below 0.3 mm, dissolves fully in engine oil."
  keywords = "organic fullerene additive,anti friction additive,C60 lubricant additive,engine oil additive"
  sub = "Modified C60 · N-Mo Bonded · Friction Coefficient ≈ 0.02"
  desc = "A very yellow, high-transparent, fully oil-soluble liquid: the organic additive is a modification of C60 fullerenes. The modified fullerene produces polarity and binds with N-Mo to form organic fullerene that completely dissolves in lubricating oil. Its unique lubrication structure creates a chemical adsorption film, a special element penetration layer and a eutectic rolling lubrication layer — a multi-element lubrication mode that greatly improves extreme pressure and anti-wear performance. Four-ball machine friction coefficient is about 0.02 with wear spot diameter below 0.3 mm; oil temperature drops over 15 °C versus conventional organic molybdenum formulations."
  tags = @("C60 Modified", "CoF ≈ 0.02", "Wear Spot &lt; 0.3 mm", "-15 °C Oil Temp")
  imgs = @("organic-fullerene-additive.jpg", "organic-fullerene-additive-2.jpg", "organic-fullerene-additive-3.jpg")
  specs = [ordered]@{
    "Appearance" = "Deep yellow, high-transparent oily liquid"
    "Structure" = "Modified C60 fullerene bonded with N-Mo"
    "Kinematic Viscosity 40 °C" = "35.3 mm²/s (GB/T 265-88)"
    "Kinematic Viscosity 100 °C" = "5.3 mm²/s (GB/T 265-88)"
    "Flash Point (Open Cup)" = "215 °C (GB/T 3536-2008)"
    "Pour Point" = "-18 °C (GB/T 3536-2006)"
    "Four-Ball Friction Coefficient" = "≈ 0.02 (min. 0.0225 measured)"
    "Wear Spot Diameter" = "&lt; 0.3 mm (0.31 mm measured)"
    "Temperature Effect" = "Oil temperature 15 °C lower than non-organic molybdenum nitride oil"
    "Application" = "Diesel / gasoline engine oil and gear oil reinforcing; self-repairing aftermarket agent"
  }
  apps = @(
    @{ h = "Premium Engine Oils"; p = "Long-duration anti-wear protection with noticeable power improvement and oil-saving effect." },
    @{ h = "Diesel Engine Oil"; p = "Proven with CH-4 15W40 formulations — halved friction coefficient in comparative tests." },
    @{ h = "Aftermarket Repair Agents"; p = "Self-repairing effect and power feel make it ideal for car care treatment products." },
    @{ h = "Gear &amp; Industrial Oils"; p = "Eutectic rolling lubrication layer reduces wear under extreme pressure." }
  )
}

$products += ,@{
  slug = "nano-anti-wear-additive"; cat = "additive"; catLabel = "Lubricant Additives"
  name = "Strong Anti-Wear Agent / Nano Anti Friction Oil Additive"
  seoTitle = "Strong Anti-Wear Agent / Nano Anti Friction Oil Additive | TOPECH"
  metaDesc = "Nano anti-wear additive with 4150 lbs load bearing, COF 0.037, PB 1200 N — saves 5-10% fuel, reduces noise 5-15 dB, works at -30 °C cold start."
  keywords = "anti friction,anti wear,engine oil additive,nano oil"
  sub = "COF 0.037 · 4150 lbs Load · PB 1200 N · -30 °C Cold Start"
  desc = "The strong anti-wear agent is made from multiple nano components that form a permeable layer and chemical reaction film on metal friction surfaces, preventing direct metal-to-metal contact under boundary lubrication. In friction demonstrations it bears more than 21 weights with a nano oil film on the abrasive wheel. Functions include 5–10% fuel saving, 1–3× longer oil change periods, 8% power increase, over 50% emission reduction, 5–15 dB noise reduction and -30 °C cold start capability."
  tags = @("21+ Weights Demo", "COF 0.037", "Fuel Saving 5-10%", "-30 °C")
  imgs = @("nano-anti-wear-additive.jpg", "nano-anti-wear-additive-2.png", "nano-anti-wear-additive-3.jpg")
  specs = [ordered]@{
    "Appearance" = "Very light yellowish liquid"
    "Density 20 °C" = "1.15–1.18 kg/m³ (GB/T 1884/1885)"
    "Kinematic Viscosity 100 °C" = "11–13 mm²/s (GB/T 265)"
    "Kinematic Viscosity 40 °C" = "120–130 mm²/s (GB/T 265)"
    "Flash Point (Open Cup)" = "≥ 213 °C (GB/T 267)"
    "Pour Point" = "-20 °C (GB/T 3535)"
    "Heating Loss (125 °C, 3 h)" = "0.10–0.14% (GB/T 7325)"
    "Copper Corrosion (121 °C, 3 h)" = "≤ 1 (GB/T 5096)"
    "Load Bearing Ability" = "4150 lbs"
    "Coefficient of Friction" = "0.037 dynamic"
    "Anti-Friction Improvement" = "0.35 mm wear area / 83% improved"
    "Four-Ball PB" = "1200 N (GB/T 31421)"
    "Storage" = "Per SH/T 0164; dry, ventilated, below 45 °C; blending ≤ 75 °C"
  }
  apps = @(
    @{ h = "Fuel-Economy Engine Oils"; p = "5–10% fuel and oil consumption saving with measurable power increase." },
    @{ h = "Heavy-Duty Fleets"; p = "Extended oil drain intervals and lower operating temperature cut fleet maintenance cost." },
    @{ h = "Cold Climate Operation"; p = "Reliable low-temperature start down to -30 °C." },
    @{ h = "Emission-Sensitive Markets"; p = "Over 50% tail smoke and emission reduction supports environmental compliance." }
  )
}

$products += ,@{
  slug = "metal-anti-wear-repair-agent"; cat = "additive"; catLabel = "Lubricant Additives"
  name = "Advanced Metal Anti-Wear Repair Agent (Nitrogen &amp; Boron Complex)"
  seoTitle = "Advanced Metal Anti-Wear Repair Agent, Nitrogen Boron Complex | TOPECH"
  metaDesc = "Eco-friendly anti-wear repair agent without sulfur, phosphorus or chlorine — forms boron nitride ceramic film, fully soluble, effective at 3% or less."
  keywords = "metal anti wear repair agent,nitrogen boron complex additive,ceramic film additive"
  sub = "Sulfur / Phosphorus / Chlorine Free · Boron Nitride Ceramic Film · ≤3% Dosage"
  desc = "A light yellow transparent synthetic oily liquid — our self-developed, environmentally friendly anti-wear repair agent that contains no sulfur, phosphorus, chlorine, nano powder or metal composition. Using advanced esterification complex technology, the nitrogen and boron complex forms an ultra-wear ceramic boron nitride molecular film on friction surfaces under engine temperature and pressure. It dissolves completely in any oil or grease; at a dosage of 3% or less, anti-wear, anti-friction and extreme-pressure effects are already obvious."
  tags = @("S/P/Cl Free", "BN Ceramic Film", "≤3% Dosage", "Eco-Friendly")
  imgs = @("metal-anti-wear-repair-agent.jpg")
  specs = [ordered]@{
    "Appearance" = "Light yellow transparent synthetic oily liquid"
    "Composition" = "Nitrogen and boron complex — no sulfur, phosphorus, chlorine, nano powder or metal"
    "Technology" = "Advanced esterification complex technology"
    "Working Mechanism" = "Forms boron nitride ceramic molecular film under temperature &amp; pressure"
    "Solubility" = "Completely dissolved in any oil and grease"
    "Recommended Dosage" = "≤ 3% — obvious anti-wear, anti-friction and extreme-pressure effect"
    "Environmental Profile" = "Self-developed eco-friendly formulation"
  }
  apps = @(
    @{ h = "Engine Repair Treatments"; p = "Rebuild worn surfaces with in-situ boron nitride ceramic film formation." },
    @{ h = "Low-SAPS Formulations"; p = "Sulfur / phosphorus / chlorine free chemistry protects catalysts and DPF systems." },
    @{ h = "Industrial Gear Oils"; p = "Extreme-pressure enhancement without corrosive elements." },
    @{ h = "Aftermarket Additives"; p = "Metal-repair positioning for car care and fleet maintenance products." }
  )
}

$products += ,@{
  slug = "boride-ep-drilling-lubricant"; cat = "additive"; catLabel = "Lubricant Additives"
  name = "LY-3010 Boride Rock Drilling Extreme Pressure Lubricant"
  seoTitle = "LY-3010 Boride Rock Drilling Extreme Pressure Lubricant | TOPECH"
  metaDesc = "Boride extreme pressure drilling lubricant — PB 95 kg, friction resistance reduction over 90%, good thermal stability after 16 h hot rolling, 1-3% dosage."
  keywords = "boride lubricant,drilling extreme pressure lubricant,rock drilling lubricant"
  sub = "PB 95 kg · Friction Reduction &gt; 90% · 1–3% Dosage"
  desc = "The boride extreme pressure lubricant performs significantly in mineral oil-based drilling lubricants and ester-base systems. It forms an inorganic / organic / polymer multi-layer composite film adsorbed on metal and wall surfaces, converting metal-to-metal and metal-to-rock contact into friction between metal and composite film — reducing the friction resistance coefficient by more than 90%. After 16 h of high-temperature hot rolling, the friction coefficient changes very little, showing excellent thermal stability. Drilling cuttings roll into hard, easy-to-clean particles with good inhibition."
  tags = @("PB 95 kg", "&gt;90% Reduction", "16 h Hot Rolling Stable", "1-3% Dosage")
  imgs = @("boride-ep-drilling-lubricant.png")
  specs = [ordered]@{
    "Model" = "LY-3010"
    "Appearance" = "Light yellow oil-soluble liquid"
    "PB Value" = "95 kg"
    "Torque Lubrication Coefficient Reduction" = "&gt; 90%"
    "Thermal Stability" = "Friction coefficient nearly unchanged after 16 h high-temperature hot rolling"
    "Film Mechanism" = "Inorganic / organic / polymer multi-layer composite adsorption film"
    "Cuttings Behavior" = "High rolling recovery rate; hard cuttings, easy to clean and filter"
    "Recommended Dosage" = "1–3%"
    "Application" = "Large displacement wells, large inclination wells and horizontal sections"
  }
  apps = @(
    @{ h = "Horizontal Well Drilling"; p = "Very smooth drilling in horizontal sections with stable EP lubrication." },
    @{ h = "Extended-Reach Wells"; p = "Torque and drag reduction above 90% eases long-reach operations." },
    @{ h = "Ester-Based Muds"; p = "Good compatibility and extreme pressure performance in ester base fluids." },
    @{ h = "Wellbore Stability"; p = "Inhibitive film and hard cuttings support clean, stable wellbores." }
  )
}

$products += ,@{
  slug = "engine-oil-system-cleaner"; cat = "additive"; catLabel = "Lubricant Additives"
  name = "Engine Oil System Cleaner"
  seoTitle = "Engine Oil System Cleaner, 300 ml Flush | TOPECH"
  metaDesc = "Engine oil system cleaner dissolves carbon deposits and varnish, releases stuck rings and lifters — 300 ml treats up to 5 liters of oil, 15-minute flush."
  keywords = "engine oil system cleaner,oil flush,engine flush additive"
  sub = "300 ml · Treats up to 5 L Oil · 15-Minute Idle Flush"
  desc = "This agent dissolves and removes carbon deposits, varnish-tar deposits and other contaminants on cylinder-piston group parts, releasing coked piston rings and stuck hydraulic lifters while neutralizing oil oxidation. High-performance lubricating agents protect the entire oil system during cleaning. Benefits: fresh oil in a clean engine, better fuel economy, increased output, exhaust emission compliance and extended catalyst life. Suitable for 4-stroke and diesel engines, manual gearboxes and differentials."
  tags = @("300 ml", "1:15 Ratio", "4-Stroke &amp; Diesel", "15-Minute Flush")
  imgs = @("engine-oil-system-cleaner.jpg")
  specs = [ordered]@{
    "Volume" = "300 ml"
    "Coverage" = "Up to 5 liters of oil, or 1:15 mixing ratio"
    "Exposure Time" = "≈ 15 minutes at idle"
    "Functions" = "Dissolves carbon &amp; varnish-tar deposits; neutralizes oil oxidation"
    "Repairs" = "Releases coked piston rings and stuck hydraulic lifters"
    "Protection" = "High-performance lubricants protect the system during cleaning"
    "Scope" = "4-stroke engines, diesel engines, manual gearboxes, differentials"
    "Benefits" = "Fuel economy, increased output, emission compliance, catalyst life"
  }
  apps = @(
    @{ h = "Pre-Change Oil Flush"; p = "Add to warm old oil before changing — 15 minutes idle, then drain and refill." },
    @{ h = "High-Mileage Engines"; p = "Free stuck rings and lifters to restore compression and reduce oil consumption." },
    @{ h = "Workshop Service Menu"; p = "Quick, safe upsell service for garages and oil change stations." },
    @{ h = "Gearbox &amp; Differential Cleaning"; p = "Also effective for manual transmission and differential oil systems." }
  )
}

# ---------- Generate ----------
foreach ($p in $products) {
  $html = Build-Page $p
  $out = Join-Path $outDir ($p.slug + ".html")
  [System.IO.File]::WriteAllText($out, $html, $utf8)
  Write-Host "Generated: products/$($p.slug).html"
}
Write-Host "Done — $($products.Count) product pages."
