#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'optparse'
require 'fileutils'

options = {
  input: nil,
  output: nil,
  track_a: File.expand_path('../config/demo_track_a.json', __dir__)
}
OptionParser.new do |parser|
  parser.banner = 'Usage: build_demo_html.rb --input RESULTS_JSON --output DEMO_HTML [options]'
  parser.on('--input PATH', 'Simulation summary JSON') { |value| options[:input] = value }
  parser.on('--output PATH', 'Self-contained HTML demo') { |value| options[:output] = value }
  parser.on('--track-a PATH', 'Track A demo configuration JSON') { |value| options[:track_a] = value }
  parser.on('--help', 'Show this message') { puts parser; exit }
end.parse!

abort 'Missing --input PATH' unless options[:input]
abort 'Missing --output PATH' unless options[:output]
abort "Missing Track A configuration: #{options[:track_a]}" unless File.file?(options[:track_a])

data = JSON.parse(File.read(options[:input]))
track_a = JSON.parse(File.read(options[:track_a]))
FileUtils.mkdir_p(File.dirname(File.expand_path(options[:output])))

html = <<~HTML
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
  <title>RetailFlex Decision Sandbox</title>
  <style>
    :root { --green:#145a3b; --blue:#126fa6; --ink:#162833; --muted:#596974; --line:#dbe4e7; --paper:#f4f7f7; --amber:#fff3d6; --red:#963a1d; }
    * { box-sizing:border-box } body { margin:0; background:var(--paper); color:var(--ink); font:16px/1.55 system-ui,-apple-system,Segoe UI,sans-serif; }
    main { max-width:1120px; margin:auto; padding:34px 22px 56px; } .kicker { color:var(--green); font-size:.8rem; font-weight:800; letter-spacing:.09em; text-transform:uppercase; }
    h1 { font-size:clamp(2rem,5vw,3rem); line-height:1.05; margin:.22rem 0 .5rem; } h2 { margin:2.2rem 0 .65rem; } h3 { margin:.1rem 0 .45rem; font-size:1.05rem; }
    .muted { color:var(--muted) } .boundary { margin:22px 0; padding:14px 17px; background:var(--amber); border-left:5px solid #ba7800; border-radius:5px; }
    .grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(210px,1fr)); gap:14px; } .card,.panel { background:#fff; border:1px solid var(--line); border-radius:11px; padding:17px; box-shadow:0 1px 2px #13222e08; }
    .metric { font-size:1.45rem; font-weight:780; line-height:1.2; margin-top:4px; } .good { color:var(--green) } .risk { color:var(--red); font-weight:750; } .tag { display:inline-block; border-radius:999px; padding:2px 9px; background:#e5f1eb; color:var(--green); font-size:.78rem; font-weight:750; }
    .tag.warn { background:#fff1d0; color:#815000 } .tag.no { background:#f9e5dd; color:var(--red) } .steps { display:grid; grid-template-columns:repeat(auto-fit,minmax(220px,1fr)); gap:12px; counter-reset:step; }
    .step { background:#fff; border-top:4px solid var(--green); border-radius:9px; padding:15px; border-left:1px solid var(--line); border-right:1px solid var(--line); border-bottom:1px solid var(--line); } .num { color:var(--green); font-weight:800; }
    table { width:100%; border-collapse:collapse; background:#fff; font-size:.94rem; } th,td { padding:10px; vertical-align:top; border-bottom:1px solid var(--line); text-align:left; } th { background:#e7f0eb; } .table-wrap { overflow-x:auto; border:1px solid var(--line); border-radius:10px; }
    svg { width:100%; height:310px; background:#fff; border:1px solid var(--line); border-radius:10px; } button { color:#fff; background:var(--green); border:0; border-radius:7px; padding:8px 11px; margin:0 7px 10px 0; cursor:pointer; font:inherit; } button.off { background:#80958a; }
    ul { margin:.45rem 0 0; padding-left:1.15rem } li { margin:.25rem 0 } .footer { color:var(--muted); font-size:.88rem; margin-top:28px; } a { color:var(--blue); } @media print { body{background:#fff}.boundary,.card,.panel,.step{box-shadow:none}button{display:none} }
  </style>
</head>
<body><main>
  <div class="kicker">University of Arkansas · NED³ · public screening demonstration</div>
  <h1>RetailFlex Decision Sandbox</h1>
  <p class="muted">Representative Northwest Arkansas SuperMarket prototype · annual EnergyPlus simulations · Track A product workflow</p>
  <div class="boundary" id="boundary"></div>
  <section class="grid" id="cards"></section>

  <h2>Decision path</h2>
  <p class="muted">Each stage increases the permitted claim only when the necessary evidence is present.</p>
  <section class="steps" id="workflow"></section>

  <h2>Illustrative peak-day comparison</h2>
  <p class="muted">Selected summer event day: <strong id="day"></strong>; modeled event window: <strong id="window"></strong>. Hourly facility electricity is presented as average kW.</p>
  <div id="toggles"></div><svg id="chart" viewBox="0 0 1000 310" role="img" aria-label="Hourly facility electricity comparison"></svg>
  <div class="table-wrap"><table><thead><tr><th>Case</th><th>Annual site electricity</th><th>Annual peak</th><th>Event-window energy</th><th>Screening decision</th></tr></thead><tbody id="scenarioRows"></tbody></table></div>

  <h2>Readiness gate — synthetic example only</h2>
  <p class="muted">This metadata example demonstrates the gate logic. It contains no owner, site, model, utility, tariff, or BMS data.</p>
  <section class="grid" id="readiness"></section>

  <h2>Bounded measure library</h2>
  <p class="muted">A measure remains a screening candidate until its listed inputs and approval gate are satisfied.</p>
  <div class="table-wrap"><table><thead><tr><th>Measure</th><th>Status</th><th>Physical/operational mechanism</th><th>Minimum inputs</th><th>Approval gate</th></tr></thead><tbody id="measures"></tbody></table></div>

  <section class="grid" style="margin-top:16px"><div class="panel"><h2>What a real assessment needs</h2><ul><li>Controlled model revision, store format, HVAC/refrigeration configuration</li><li>12 months of interval whole-building electricity and the applicable tariff</li><li>Operating schedules, temperature/operations constraints, and meter boundary</li><li>Approved read-only BMS trends and point dictionary where relevant</li></ul></div><div class="panel"><h2>Appropriate next action</h2><p>Approve a limited data-and-operations scoping meeting and complete the local intake manifest. The workflow can recommend collecting data, redesigning a measure, or rejecting a scenario; it does not request live control.</p></div></section>
  <p class="footer">Generated from versioned prototype scenarios and synthetic Track A metadata. This page is not a Walmart analysis, operating instruction, safety assessment, or savings guarantee. The public repository contains no controlled store model or data.</p>
</main>
<script>
const d=#{JSON.generate(data)}; const t=#{JSON.generate(track_a)}; const s=Object.values(d.summaries); const base=d.summaries.baseline;
const fmt=n=>n.toLocaleString(undefined,{maximumFractionDigits:0}); const verdict=x=>x.id==='baseline'?'Reference case':x.event_window_kwh<base.event_window_kwh?'Candidate for further review':'Reject or redesign before pilot';
document.querySelector('#boundary').textContent=d.claim_boundary; document.querySelector('#day').textContent=d.event_day; document.querySelector('#window').textContent=d.event_window;
document.querySelector('#cards').innerHTML=`<div class="card"><div class="muted">Evidence class</div><div class="metric">Simulated prototype</div></div><div class="card"><div class="muted">Synthetic readiness state</div><div class="metric good">Ready with warnings</div></div><div class="card"><div class="muted">Baseline annual electricity</div><div class="metric">${fmt(base.annual_site_kwh)} kWh</div></div><div class="card"><div class="muted">Primary decision</div><div class="metric">Data scope / redesign</div></div>`;
document.querySelector('#workflow').innerHTML=t.workflow.map(x=>`<article class="step"><div class="num">STEP ${x.step}</div><h3>${x.title}</h3><div class="muted"><strong>Evidence:</strong> ${x.evidence}</div><p><strong>Decision:</strong> ${x.decision}</p></article>`).join('');
document.querySelector('#scenarioRows').innerHTML=s.map(x=>`<tr><td><strong>${x.label}</strong><br><span class="muted">${x.description}</span></td><td>${fmt(x.annual_site_kwh)} kWh</td><td>${fmt(x.annual_peak_kw)} kW</td><td>${fmt(x.event_window_kwh)} kWh</td><td class="${verdict(x).startsWith('Reject')?'risk':''}">${verdict(x)}</td></tr>`).join('');
const r=t.readiness_example; document.querySelector('#readiness').innerHTML=`<div class="card"><span class="tag warn">${r.status.replaceAll('_',' ')}</span><h3>${r.label}</h3><p>${r.next_step}</p></div><div class="card"><h3>Available metadata</h3><ul>${r.available.map(x=>`<li>${x}</li>`).join('')}</ul></div><div class="card"><h3>Still pending</h3><ul>${r.pending.map(x=>`<li>${x}</li>`).join('')}</ul></div><div class="card"><h3>Still prohibited</h3><ul>${r.blocked_actions.map(x=>`<li class="risk">${x}</li>`).join('')}</ul></div>`;
document.querySelector('#measures').innerHTML=t.measure_library.map(x=>`<tr><td><strong>${x.name}</strong></td><td><span class="tag ${x.state==='out of scope'?'no':x.state==='QA candidate'?'warn':''}">${x.state}</span></td><td>${x.mechanism}</td><td>${x.minimum_inputs}</td><td>${x.approval_gate}</td></tr>`).join('');
const colors=['#145a3b','#126fa6','#c5661b']; let shown=new Set(s.map(x=>x.id)); function draw(){document.querySelector('#toggles').innerHTML=s.map((x,i)=>`<button class="${shown.has(x.id)?'':'off'}" onclick="toggleCase('${x.id}')">${x.label}</button>`).join(''); const all=s.flatMap(x=>x.event_day_hourly_kw.map(p=>p.kw)); const max=Math.ceil(Math.max(...all)/20)*20; let out=''; for(let y=0;y<=max;y+=max/4){const py=265-y/max*225;out+=`<line x1="55" y1="${py}" x2="970" y2="${py}" stroke="#dfe5e8"/><text x="5" y="${py+4}" font-size="12">${Math.round(y)} kW</text>`} for(let h=0;h<24;h+=3){const x=55+h/23*915;out+=`<text x="${x-8}" y="290" font-size="12">${h}:00</text>`} s.forEach((x,i)=>{if(!shown.has(x.id))return;const pts=x.event_day_hourly_kw.map(p=>`${55+p.hour/23*915},${265-p.kw/max*225}`).join(' ');out+=`<polyline points="${pts}" fill="none" stroke="${colors[i]}" stroke-width="3"/><text x="650" y="${27+i*20}" fill="${colors[i]}" font-size="13">${x.label}</text>`}); document.querySelector('#chart').innerHTML=out;} window.toggleCase=id=>{shown.has(id)?shown.delete(id):shown.add(id);draw()}; draw();
</script></body></html>
HTML

File.write(options[:output], html)
puts "Wrote #{options[:output]}"
