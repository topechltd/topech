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
      <video controls preload="metadata" title="$($v.note)" poster="../images/products/$($v.poster)">
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
  # Append product-specific extra FAQ if defined
  if ($d.extraFaq) { $faqItems += $d.extraFaq }
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

  # VideoObject structured data (video rich results + AI search citation)
  $ldVideo = ""
  if ($d.videos) {
    $vidList = ""
    $vidCount = 0
    foreach ($v in $d.videos) {
      if ($vidCount -gt 0) { $vidList += ",`r`n" }
      $vidList += "    { `"@type`": `"VideoObject`", `"name`": `"$(JsonEsc $v.note)`", `"description`": `"$(JsonEsc $v.note)`", `"thumbnailUrl`": `"$siteBase/images/products/$($v.poster)`", `"contentUrl`": `"$siteBase/videos/$($v.src)`", `"uploadDate`": `"2026-08-17`" }"
      $vidCount++
    }
    $ldVideo = @"
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@graph": [
$vidList
  ]
}
</script>
"@
  }

  $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<!-- Meta Pixel Code -->
<script>
!function(f,b,e,v,n,t,s)
{if(f.fbq)return;n=f.fbq=function(){n.callMethod?
n.callMethod.apply(n,arguments):n.queue.push(arguments)};
if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
n.queue=[];t=b.createElement(e);t.async=!0;
t.src=v;s=b.getElementsByTagName(e)[0];
s.parentNode.insertBefore(t,s)}(window, document,'script',
'https://connect.facebook.net/en_US/fbevents.js');
fbq('init', '1821520142169884');
fbq('track', 'PageView');
fbq('track', 'ViewContent', {content_name: '$($d.name)', content_category: '$($d.catLabel)'});
</script>
<noscript><img height="1" width="1" style="display:none"
src="https://www.facebook.com/tr?id=1821520142169884&ev=PageView&noscript=1"
/></noscript>
<!-- End Meta Pixel Code -->
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
$ldVideo
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
  name = "Timken Oil Friction Tester, Portable Lubricity Tester"
  seoTitle = "Timken Oil Friction Tester, Portable Lubricity Tester | ASTM D2782 | TOPECH"
  metaDesc = "TOPECH Timken oil friction tester (ASTM D2782) demonstrates lubricant anti-wear performance. OK load test: ordinary oil locks at 3-4 weights, anti-wear oil runs past 12 weights."
  keywords = "Timken tester,Timken machine,Timken oil friction tester,Timken OK load tester,lubricity tester,oil abrasion tester,anti wear tester,four ball tester,block on ring tester,ASTM D2782,ASTM D2509,extreme pressure tester"
  sub = "Timken OK Load Test · Lubricity Demo Machine · 12 Weights · 220 V"
  desc = "The TOPECH Timken oil friction tester (also called Timken machine or lubricity tester) evaluates lubricant anti-wear and extreme pressure performance using the Timken OK load method per ASTM D2782 and ASTM D2509. Under 220 V test conditions, ordinary oil locks the machine at 3-4 weights (OK value), while anti-wear oil allows more than 12 weights without lock-up — a dramatic, visual demonstration of lubricant quality. This portable block-on-ring tester is ideal for lubricant distributors, additive manufacturers and quality control labs. Standard packing includes the machine body, 12 weights, 2 iron oil cups, 2 oil stones, power cable, 30 steel balls, a spare abrasive wheel and a portable aluminum case."
  tags = @("Timken OK Load", "ASTM D2782", "12 Weights", "220 V", "Portable Case", "Demo Video")
  extraFaq = @(
    @{ q = "What is the Timken OK load test method?"; a = "The Timken OK load test (ASTM D2782 / ASTM D2509) measures the maximum load a lubricant can support before the oil film ruptures. A rotating ring presses against a fixed steel block under increasing weight. The highest load without scoring or lock-up is the OK value — higher OK values indicate superior anti-wear and extreme pressure performance." },
    @{ q = "Is this a Timken machine or a four ball tester?"; a = "This is a Timken-type block-on-ring tester, not a four ball machine. The Timken method uses a rotating ring against a fixed block (line contact), while four ball testers use four steel balls in point contact. Both are valid for evaluating lubricant anti-wear performance, but Timken testers are preferred for demonstration and quality screening." },
    @{ q = "What standards does this Timken tester comply with?"; a = "The TOPECH Timken tester is designed according to ASTM D2782 (extreme pressure properties of lubricating fluids) and ASTM D2509 (load-carrying capacity of lubricating greases). It is also compatible with Chinese standards GB/T 11144 and SH/T 0203." },
    @{ q = "Can I use this Timken tester for both engine oil and gear oil?"; a = "Yes. The Timken tester works with engine oils, gear oils, hydraulic oils, lubricating greases and cutting fluids. The visual lock-up comparison makes it ideal for quality control and customer demonstrations across all lubricant types." }
  )
  imgs = @("oil-friction-tester.jpg", "oil-friction-tester-front.jpg", "oil-friction-tester-panel.jpg", "oil-friction-tester-weights.jpg", "oil-friction-tester-case.jpg", "oil-friction-tester-case-2.jpg", "oil-friction-tester-case-3.jpg")
    videos = @( @{ src = "timken-bearing-anti-wear-test-full.mp4"; poster = "oil-friction-tester-panel.jpg"; note = "Timken Bearing Anti-Wear Test — real-world demonstration on the TOPECH Timken Oil Friction Tester: high load capacity, minimal wear, stable rotation and long service life." } )
  specs = [ordered]@{
    "Model" = "Timken Oil Friction Tester (Lubricity Tester)"
    "Test Method" = "Timken OK Load Method (ASTM D2782 / ASTM D2509)"
    "Test Voltage" = "AC 220 V"
    "Weights" = "12 pcs, each ≈ 100 kg load on the friction pair"
    "OK Value (Ordinary Oil)" = "3–4 weights lock-up"
    "OK Value (Anti-Wear Oil)" = "More than 12 weights without lock-up"
    "Friction Type" = "Block-on-Ring (ring rotates against fixed block)"
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
  name = "Digital Anti-Wear Tester with Timken OK Load Display"
  seoTitle = "Digital Anti-Wear Tester with Five Displays | Timken Machine | TOPECH"
  metaDesc = "TOPECH digital anti-wear tester with five displays shows voltage, current, power, energy and oil temperature during Timken OK load friction tests."
  keywords = "digital anti wear tester,Timken machine with display,Timken tester five display,oil friction tester digital,anti wear test machine,power consumption tester"
  sub = "Timken Test with V · A · W · kWh · Oil Temperature Displays"
  desc = "The new generation digital anti-wear tester (Timken machine) adds five digital displays showing voltage (V), current (A), instantaneous power (W), power consumption (kWh) and instantaneous oil temperature (T). Run two Timken machines side by side for a strictly fair comparison: place the same weights, run 3–5 minutes, and observe current, power and temperature differences. Lower oil temperature means better viscosity stability; lower power consumption means better fuel economy; stable color and no smoke indicate superior lubricant quality."
  tags = @("5 Digital Displays", "Side-by-Side Comparison", "Real-Time Temperature", "220 V")
  imgs = @("digital-anti-wear-tester-silver.jpg", "digital-anti-wear-tester-angle.jpg", "digital-anti-wear-tester-display.jpg", "digital-anti-wear-tester-grey.jpg", "digital-anti-wear-tester.jpg", "digital-anti-wear-tester-set.jpg", "digital-anti-wear-tester-unit.jpg", "digital-anti-wear-tester-panel.jpg")
    videos = @(
        @{ src = "timken-bearing-anti-wear-test-full.mp4"; poster = "digital-anti-wear-tester-silver.jpg"; note = "Timken Bearing Anti-Wear Test — live demonstration on the Digital Anti-Wear Tester with real-time V / A / W readings under high load conditions." },
        @{ src = "timken-bearing-water-resistance-test-full.mp4"; poster = "digital-anti-wear-tester-display.jpg"; note = "Timken Bearing Water Resistance Test — bearing exposed to water spray while running, proving anti-rust sealing and waterproof protection for harsh environments." }
      )
  specs = [ordered]@{
    "Model" = "Digital Anti-Wear Tester with Timken OK Load Display"
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
  slug = "timken-test-machine"; cat = "friction"; catLabel = "Anti-Wear Testers"
  name = "Timken Test Machine for Anti-Wear Oil Testing"
  seoTitle = "Timken Test Machine for Anti-Wear Oil Testing | ASTM D2782 | TOPECH"
  metaDesc = "TOPECH Timken test machine evaluates lubricant anti-wear performance by the Timken OK load method. Ordinary oil locks at 3-4 weights, anti-wear oil passes more than 12 weights."
  keywords = "Timken test machine,Timken testing machine,Timken machine,anti wear test machine,Timken OK load machine,ASTM D2782 machine,Timken tester price"
  sub = "Timken OK Load Method · ASTM D2782 / ASTM D2509 · Lever Loading · 220 V"
  desc = "The TOPECH Timken test machine (Timken testing machine) evaluates the anti-wear and extreme pressure performance of lubricating oils and greases using the Timken OK load method per ASTM D2782 and ASTM D2509. A rotating ring presses against a fixed steel block under lever-applied weights: ordinary oil locks the machine at 3–4 weights, while anti-wear oil keeps running past 12 weights — an instant, visual verdict on lubricant quality. The industrial green housing, torque loading lever, analog ammeter and dedicated drive motor make it a durable workhorse for lubricant companies, additive distributors and QC labs."
  tags = @("Timken OK Load", "ASTM D2782", "12 Weights", "220 V", "Block-on-Ring")
  imgs = @("timken-tester-green-front.jpg")
  videos = @( @{ src = "timken-bearing-anti-wear-test-full.mp4"; poster = "timken-tester-green-front.jpg"; note = "Timken Bearing Anti-Wear Test — real-world demonstration on the TOPECH Timken Test Machine: high load capacity, minimal wear and stable rotation." } )
  specs = [ordered]@{
    "Model" = "Timken Test Machine (Anti-Wear Oil Testing)"
    "Test Method" = "Timken OK Load Method (ASTM D2782 / ASTM D2509)"
    "Power Supply" = "AC 220 V, 50 Hz"
    "Loading" = "Lever system with graded weights"
    "OK Value (Ordinary Oil)" = "3–4 weights lock-up"
    "OK Value (Anti-Wear Oil)" = "More than 12 weights without lock-up"
    "Friction Type" = "Block-on-Ring (ring rotates against fixed block)"
    "Indication" = "Analog ammeter for load / current observation"
    "Housing" = "Industrial metal cabinet, green finish"
  }
  apps = @(
    @{ h = "Lubricant Brand Demonstration"; p = "Show customers the lock-up difference between ordinary and anti-wear oils in minutes." },
    @{ h = "Additive Distributor Sales"; p = "Portable proof of additive effect at exhibitions, workshops and customer visits." },
    @{ h = "Incoming Oil QC"; p = "Fast comparative screening of lubricant batches against a reference oil." },
    @{ h = "Training &amp; Education"; p = "Hands-on teaching of boundary lubrication and OK load concepts." }
  )
}

$products += ,@{
  slug = "timken-ok-load-tester"; cat = "friction"; catLabel = "Anti-Wear Testers"
  name = "Timken OK Load Tester with Dual Digital Display"
  seoTitle = "Timken OK Load Tester, ASTM D2782 Lubricant Tester | TOPECH"
  metaDesc = "TOPECH Timken OK load tester to ASTM D2782 / D2509 measures lubricant load-carrying capacity with dual digital display and stainless steel construction."
  keywords = "Timken OK load tester,OK load test,ASTM D2782 tester,ASTM D2509 tester,lubricant load carrying capacity tester,Timken tester dual display"
  sub = "ASTM D2782 / ASTM D2509 · Dual Digital Display · Stainless Steel Body"
  desc = "The Timken OK load tester determines the maximum load (OK value) a lubricant can carry before the oil film ruptures, per ASTM D2782 for lubricating fluids and ASTM D2509 for lubricating greases. The polished stainless steel body resists oil and corrosion, while the dual digital displays keep test parameters clearly visible during loading. Weights are applied step by step through the long lever until scoring or lock-up occurs — the last passed load is the OK value, and higher is better."
  tags = @("Timken OK Load", "Dual Digital Display", "Stainless Steel", "ASTM D2509")
  imgs = @("timken-tester-silver-angle.jpg")
  specs = [ordered]@{
    "Model" = "Timken OK Load Tester (Dual Display)"
    "Test Method" = "Timken OK Load (ASTM D2782 / ASTM D2509)"
    "Display" = "Dual digital LED displays for test parameters"
    "Power Supply" = "AC 220 V, 50 Hz"
    "Loading" = "Step weights on long lever arm"
    "Friction Type" = "Block-on-Ring (ring rotates against fixed block)"
    "Body" = "Brushed stainless steel cabinet"
    "Result" = "OK load value — highest weight passed without scoring"
  }
  apps = @(
    @{ h = "Lubricant Quality Ranking"; p = "Rank oils by OK load value — a single number customers understand." },
    @{ h = "Grease EP Verification"; p = "Load-carrying capacity checks of lubricating greases per ASTM D2509." },
    @{ h = "Additive Effect Proof"; p = "Show OK value improvement before and after additive dosing." },
    @{ h = "Technical Demonstrations"; p = "Clear, repeatable film-rupture demos for sales and training." }
  )
}

$products += ,@{
  slug = "timken-bearing-tester"; cat = "friction"; catLabel = "Anti-Wear Testers"
  name = "Timken Bearing Wear Tester for Lubricating Oil"
  seoTitle = "Timken Bearing Wear Tester for Lubricating Oil | TOPECH"
  metaDesc = "Timken bearing wear tester runs bearings against loaded blocks to demonstrate lubricant anti-wear protection for engines, gearboxes and motors."
  keywords = "Timken bearing tester,bearing wear tester,bearing anti wear test machine,oil bearing tester,lubricant bearing protection tester"
  sub = "Bearing-Level Anti-Wear Demonstration · Lever Loading · 220 V"
  desc = "The Timken bearing wear tester reproduces the boundary friction that real bearings suffer. A rotating ring (bearing contact) is pressed against a fixed block under adjustable weights while the test oil lubricates the contact zone. Good lubricants keep current stable, temperature low and the contact surface free of scoring; poor oils lock the machine within minutes. It is the most convincing way to demonstrate how an engine oil, gear oil or grease protects bearings in service."
  tags = @("Bearing Wear Test", "Anti-Wear Demo", "Lever Loading", "220 V")
  imgs = @("timken-tester-silver-top.jpg")
  specs = [ordered]@{
    "Model" = "Timken Bearing Wear Tester"
    "Test Method" = "Timken OK Load Method (ASTM D2782)"
    "Test Object" = "Bearing-type ring against fixed steel block"
    "Power Supply" = "AC 220 V, 50 Hz"
    "Loading" = "Lever with graded weights"
    "Observation" = "Current, noise, temperature, surface scoring"
    "Structure" = "Compact bench-top cabinet with side drive motor"
  }
  apps = @(
    @{ h = "Engine Oil Bearing Protection"; p = "Show how oil quality directly affects bearing life under load." },
    @{ h = "Grease Screening for Motors"; p = "Compare greases for motor and pump bearing applications." },
    @{ h = "Customer Education"; p = "Live side-by-side runs make anti-wear benefits visible." },
    @{ h = "Tribology Teaching"; p = "Demonstrate boundary lubrication failure with a real bearing contact." }
  )
}

$products += ,@{
  slug = "block-on-ring-tester"; cat = "friction"; catLabel = "Anti-Wear Testers"
  name = "Block on Ring Friction and Wear Tester"
  seoTitle = "Block on Ring Friction Wear Tester, ASTM D2509 | TOPECH"
  metaDesc = "TOPECH block on ring tester runs a fixed block against a rotating ring under increasing load to ASTM D2509 / D2782, scoring lubricant film strength."
  keywords = "block on ring tester,block on ring wear tester,ASTM D2509 tester,ASTM D2782 tester,ring and block tester,film strength tester"
  sub = "ASTM D2509 / ASTM D2782 · Block-on-Ring Geometry · Stainless Steel"
  desc = "The block on ring tester uses the classic line-contact geometry: a stationary steel block is loaded against a rotating ring immersed in the test lubricant. Load is increased stepwise through the lever-and-weight system until the lubricant film fails. The passed load (OK value) and the condition of the block surface quantify film strength and anti-wear performance per ASTM D2509 and ASTM D2782. Brushed stainless steel construction and a compact drive motor keep the machine stable, clean and easy to maintain."
  tags = @("Block-on-Ring", "ASTM D2509", "Line Contact", "Stainless Steel")
  imgs = @("timken-tester-silver-front.jpg")
  specs = [ordered]@{
    "Model" = "Block on Ring Friction and Wear Tester"
    "Standards" = "ASTM D2509, ASTM D2782"
    "Friction Geometry" = "Fixed block against rotating ring (line contact)"
    "Power Supply" = "AC 220 V, 50 Hz"
    "Loading" = "Lever arm with calibrated step weights"
    "Body" = "Brushed stainless steel housing"
    "Test Kit" = "Standard test blocks and rings included"
    "Observation" = "Scoring, lock-up and OK load rating"
  }
  apps = @(
    @{ h = "Grease Load-Carrying Tests"; p = "ASTM D2509 OK load determination for lubricating greases." },
    @{ h = "Lubricant Research"; p = "Controlled line-contact wear studies for formulation work." },
    @{ h = "Batch Quality Control"; p = "Standardized scoring criteria for repeatable batch release." },
    @{ h = "Film Strength Demos"; p = "Show film strength differences between oils at trade shows." }
  )
}

$products += ,@{
  slug = "portable-timken-tester"; cat = "friction"; catLabel = "Anti-Wear Testers"
  name = "Portable Timken Oil Test Machine with Case Kit"
  seoTitle = "Portable Timken Oil Test Machine, Mobile Lubricity Tester Kit | TOPECH"
  metaDesc = "Portable Timken oil test machine packed in a protective case with control box, motor and full accessory kit — take anti-wear demonstrations anywhere."
  keywords = "portable Timken tester,portable oil test machine,mobile lubricant tester,oil tester kit,Timken tester with case,portable lubricity tester"
  sub = "Complete Case Kit · Control Box + Motor · Field Demonstration Ready"
  desc = "The portable Timken oil test machine brings the classic Timken OK load demonstration out of the lab. The kit ships in a protective transport case containing the control box with ammeter and power switch, the finned drive motor, loading hardware and all accessories needed for on-site anti-wear demonstrations. Set it up in minutes at customer premises, exhibitions or training venues, run the weight-loading test, and let the machine speak for your lubricant. Ideal for additive sales teams and lubricant distributors who travel."
  tags = @("Portable Kit", "Transport Case", "Field Demo", "220 V")
  imgs = @("timken-tester-portable-case.jpg")
  specs = [ordered]@{
    "Model" = "Portable Timken Oil Test Machine"
    "Test Method" = "Timken OK Load Method (ASTM D2782)"
    "Configuration" = "Separate control box + drive motor unit"
    "Power Supply" = "AC 220 V, 50 Hz"
    "Indication" = "Analog ammeter + power switch on control panel"
    "Loading" = "Lever with graded weights"
    "Package" = "Protective transport case with foam inserts"
    "Setup Time" = "Minutes — ready for on-site demonstrations"
  }
  apps = @(
    @{ h = "On-Site Customer Demos"; p = "Run live anti-wear comparisons at the customer's workshop or office." },
    @{ h = "Exhibition &amp; Roadshow"; p = "Lightweight case kit travels easily to trade shows and events." },
    @{ h = "Distributor Training"; p = "Teach sales teams how to demonstrate lubricant quality in the field." },
    @{ h = "Mobile Oil QC"; p = "Quick comparative checks of delivered oil batches at warehouses." }
  )
}

$products += ,@{
  slug = "lubricant-anti-wear-tester"; cat = "friction"; catLabel = "Anti-Wear Testers"
  name = "Lubricant Anti-Wear Performance Tester with Temperature Display"
  seoTitle = "Lubricant Anti-Wear Performance Tester, Oil Temperature Display | TOPECH"
  metaDesc = "Lubricant anti-wear performance tester with live oil temperature display and weight loading — compare anti-wear quality of oils by OK load and temperature."
  keywords = "lubricant anti wear tester,anti wear performance tester,oil anti wear test machine,lubricant testing equipment,oil quality tester"
  sub = "Oil Temperature Display · Weight Loading · Anti-Wear Comparison"
  desc = "The lubricant anti-wear performance tester combines the Timken OK load test with live oil temperature monitoring. During loading, the digital temperature display tracks how the lubricant behaves under friction — anti-wear oils stay cooler while poor oils heat up fast. Together with the stacked weight loading system, this gives two independent proofs of lubricant quality in a single 3–5 minute run: OK load value and temperature rise. A compact green cabinet, silver control panel and precision lever make it suitable for showrooms, labs and training centers."
  tags = @("Temperature Display", "Weight Loading", "Anti-Wear Comparison", "220 V")
  imgs = @("timken-tester-green-detail.jpg")
  specs = [ordered]@{
    "Model" = "Lubricant Anti-Wear Performance Tester"
    "Test Method" = "Timken OK Load Method (ASTM D2782)"
    "Display" = "Digital oil temperature display (°C)"
    "Power Supply" = "AC 220 V, 50 Hz"
    "Loading" = "Stacked step weights on loading lever"
    "Test Duration" = "3–5 minutes per comparative run"
    "Observation" = "OK load value + temperature rise"
    "Housing" = "Green metal cabinet with silver control panel"
  }
  apps = @(
    @{ h = "Oil Brand Comparison"; p = "Side-by-side OK load and temperature data make quality differences obvious." },
    @{ h = "Showroom Demonstration"; p = "Compact and presentable — perfect for lubricant store counters." },
    @{ h = "Anti-Wear Additive Proof"; p = "Quantify temperature reduction and OK load gain after dosing." },
    @{ h = "Quality Screening"; p = "Fast go / no-go check of incoming lubricant batches." }
  )
}

$products += ,@{
  slug = "timken-extreme-pressure-tester"; cat = "friction"; catLabel = "Anti-Wear Testers"
  name = "Timken Extreme Pressure and Anti-Wear Tester"
  seoTitle = "Timken Extreme Pressure Tester, EP Anti-Wear Test Machine | TOPECH"
  metaDesc = "Timken extreme pressure tester loads the friction pair with stacked weights to evaluate EP and anti-wear performance of oils and greases to ASTM D2782."
  keywords = "extreme pressure tester,EP tester,extreme pressure anti wear tester,Timken EP test machine,load carrying tester,gear oil EP tester"
  sub = "Extreme Pressure Loading · Stacked Weights · ASTM D2782"
  desc = "The Timken extreme pressure tester pushes lubricants to their limits. Stacked weights on the loading lever apply progressively heavier loads to the block-on-ring friction pair until the oil film breaks — revealing the true extreme pressure (EP) reserve of gear oils, engine oils and greases. Oils with genuine EP additives carry dramatically higher loads than ordinary oils, and the difference is impossible to fake. Built with a rugged black-finish cabinet, precision lever mechanism and reliable drive motor for years of heavy-duty demonstration and QC use."
  tags = @("Extreme Pressure", "Stacked Weights", "ASTM D2782", "Heavy-Duty")
  imgs = @("timken-tester-black-weights.jpg")
  specs = [ordered]@{
    "Model" = "Timken Extreme Pressure and Anti-Wear Tester"
    "Test Method" = "Timken OK Load Method (ASTM D2782)"
    "Loading" = "Stacked step weights on precision lever"
    "Power Supply" = "AC 220 V, 50 Hz"
    "Friction Type" = "Block-on-Ring (ring rotates against fixed block)"
    "Result" = "Maximum passed load — EP reserve of the lubricant"
    "Housing" = "Rugged black metal cabinet"
    "Suitable Oils" = "Gear oils, engine oils, greases, hydraulic oils"
  }
  apps = @(
    @{ h = "Gear Oil EP Rating"; p = "Demonstrate the extreme pressure reserve of gear oils under heavy loads." },
    @{ h = "Grease Load Testing"; p = "Rank greases by maximum passed load for demanding applications." },
    @{ h = "Additive Sales Proof"; p = "EP additive effect shown live with stacked weight loading." },
    @{ h = "Heavy-Duty QC"; p = "Robust construction suits frequent industrial quality checks." }
  )
}

$products += ,@{
  slug = "oil-wear-test-machine"; cat = "friction"; catLabel = "Anti-Wear Testers"
  name = "Oil Friction Wear Testing Machine"
  seoTitle = "Oil Friction Wear Testing Machine, Anti-Wear Tester | TOPECH"
  metaDesc = "Oil friction wear testing machine for lubricant anti-wear demonstration and QC — Timken OK load method, weight loading, works with oils and greases."
  keywords = "oil wear test machine,friction wear testing machine,oil friction wear tester,wear testing machine,lubricant wear tester,anti wear testing equipment"
  sub = "Friction &amp; Wear Testing · Timken OK Load · Oils and Greases"
  desc = "The oil friction wear testing machine is a general-purpose anti-wear test platform for lubricating oils and greases. Based on the Timken OK load method, it loads a rotating ring against a fixed block with graded weights to reveal friction, wear and film-failure behavior of the test lubricant. Results are immediate and visual — current, noise and lock-up tell you whether the oil protects. The green industrial cabinet, adjustable loading lever and torque indicator make it easy to operate for technicians and sales staff alike."
  tags = @("Friction Wear Test", "Timken OK Load", "Oils &amp; Greases", "220 V")
  imgs = @("timken-tester-green-angle.jpg")
  videos = @( @{ src = "timken-bearing-water-resistance-test-full.mp4"; poster = "timken-tester-green-angle.jpg"; note = "Timken Bearing Water Resistance Test — bearing exposed to water while running, proving protection in harsh environments." } )
  specs = [ordered]@{
    "Model" = "Oil Friction Wear Testing Machine"
    "Test Method" = "Timken OK Load Method (ASTM D2782)"
    "Power Supply" = "AC 220 V, 50 Hz"
    "Loading" = "Adjustable lever with graded weights"
    "Friction Type" = "Block-on-Ring (ring rotates against fixed block)"
    "Indication" = "Torque / load indicator on control panel"
    "Suitable Samples" = "Engine oils, gear oils, hydraulic oils, greases"
    "Housing" = "Green industrial metal cabinet"
  }
  apps = @(
    @{ h = "General Anti-Wear QC"; p = "Routine wear-protection checks of lubricants before use or sale." },
    @{ h = "Lubricant Comparison"; p = "Rank competing oils by lock-up behavior and OK load value." },
    @{ h = "Sales Demonstration"; p = "Simple operation lets any salesperson run a convincing test." },
    @{ h = "Education &amp; Training"; p = "Teach friction, wear and lubrication fundamentals hands-on." }
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
