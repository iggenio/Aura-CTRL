<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<!--
  Aura-CTRL 1.0.0 - WebUI page
  SPDX-License-Identifier: GPL-3.0-or-later
  Copyright (C) 2026 iggenio
  Developed with the assistance of Claude (Anthropic), an AI model.
  Licensed under the GNU General Public License v3.0 or later.
  See the LICENSE file or <https://www.gnu.org/licenses/>.
-->
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta HTTP-EQUIV="Pragma" CONTENT="no-cache">
<meta HTTP-EQUIV="Expires" CONTENT="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title>Aura-CTRL</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<script language="JavaScript" type="text/javascript" src="/js/jquery.js"></script>
<script>if (typeof window.jQuery == 'undefined') document.write('<script language="JavaScript" type="text/javascript" src="/jquery.js"><\/script>');</script>
<script language="JavaScript" type="text/javascript" src="/js/httpApi.js"></script>
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<style>
/* Aura-CTRL page. Layout: Merlin page frame and FormTable sections; inside them flex/grid blocks.
   Colours follow the Merlin WebUI (panel #2b373b, accent #ffcc00). The Merlin FormTable colours every span
   yellow and styles nested tables: this page uses classed elements and !important where it must win. */
#ac_root{--ac-panel:#2b373b;--ac-inset:#24302f;--ac-deep:#1f2a2e;--ac-line:#3e4f54;--ac-line2:#6b7f84;--ac-text:#ffffff;--ac-muted:#b8c4c8;--ac-soft:#d3dcdf;--ac-accent:#ffcc00;--ac-ok:#8BC34A;--ac-warn:#FFC107;--ac-bad:#FF5252;}
#ac_root, #ac_root *{box-sizing:border-box;}
.FormTable td span:not([class]), .FormTable thead td span:not([class]){color:inherit;background-color:transparent;}
#ac_root .FormTable td span, #ac_root .FormTable thead td span{background-color:transparent;}
.ac-help{display:block;margin-top:5px;font-size:11px;line-height:1.45;color:var(--ac-muted) !important;max-width:560px;}
.ac-ok{color:var(--ac-ok) !important;font-weight:bold;}
.ac-warn{color:var(--ac-warn) !important;font-weight:bold;}
.ac-bad{color:var(--ac-bad) !important;font-weight:bold;}
.ac-muted{color:var(--ac-muted) !important;}
.ac-mono{font-family:monospace;font-size:11px;}
/* header */
.ac-top{display:flex;justify-content:space-between;align-items:center;gap:16px;}
.ac-top .formfonttitle{margin:0;}
.ac-ver{font-size:12px;font-weight:normal;color:var(--ac-muted) !important;margin-left:6px;}
.ac-master{display:flex;align-items:center;gap:10px;font-size:12px;color:var(--ac-soft) !important;}
.ac-intro{margin:4px 0 12px;font-size:12px;line-height:1.5;color:var(--ac-soft) !important;}
/* switch */
.ac-sw{position:relative;display:inline-block;width:56px;height:24px;border-radius:12px;border:0;padding:0;cursor:pointer;vertical-align:middle;flex:0 0 auto;font:bold 10px/24px Verdana,Arial,sans-serif;}
.ac-sw.on{background:#4caf50 !important;color:#fff !important;text-align:left;padding-left:9px;}
.ac-sw.off{background:#6b7f84 !important;color:#fff !important;text-align:right;padding-right:9px;}
.ac-sw .knob{position:absolute;top:3px;width:18px;height:18px;border-radius:50%;background:#fff !important;}
.ac-sw.on .knob{right:3px;}
.ac-sw.off .knob{left:3px;}
.ac-sw:focus-visible, .ac-btn:focus-visible, .ac-pick:focus-visible, .ac-tile:focus-visible, .ac-seg-btn:focus-visible{outline:2px solid var(--ac-accent);outline-offset:2px;}
/* status card */
.ac-status{display:grid;grid-template-columns:240px 1fr auto;gap:18px;align-items:center;padding:14px 16px;background:var(--ac-panel);border:1px solid var(--ac-line2);border-radius:4px;}
.ac-status .ac-bar{width:100%;}
.ac-now{min-width:0;}
.ac-now-label{font-size:11px;letter-spacing:.05em;text-transform:uppercase;color:var(--ac-muted) !important;}
.ac-now-title{font-size:15px;font-weight:bold;color:var(--ac-text) !important;margin:2px 0;}
.ac-now-detail{font-size:12px;color:var(--ac-soft) !important;}
.ac-chips{display:flex;flex-wrap:wrap;gap:6px;margin-top:8px;}
.ac-chip{display:inline-flex;align-items:center;gap:6px;padding:3px 9px;border-radius:12px;background:var(--ac-deep);border:1px solid var(--ac-line);font-size:11px;color:var(--ac-text) !important;}
.ac-dot{width:9px;height:9px;border-radius:50%;flex:0 0 auto;}
.ac-detail{display:block;margin-top:6px;font-size:11px;color:var(--ac-soft) !important;}
.ac-updated{display:block;margin-top:8px;font-size:10px;color:var(--ac-muted) !important;}
/* tabs */
.ac-tabs{display:flex;gap:6px;margin:16px 0 0;padding:0 4px;border-bottom:2px solid var(--ac-line2);}
.ac-tab{display:inline-flex;align-items:center;gap:8px;padding:10px 20px;margin-bottom:-2px;border:1px solid var(--ac-line);border-top:3px solid var(--ac-line);border-bottom:0;border-radius:6px 6px 0 0;background:#1a2326;color:var(--ac-muted) !important;font:bold 13px Verdana,Arial,sans-serif;cursor:pointer;}
.ac-tab:hover{background:#26333a;color:#fff !important;}
.ac-tab.sel{background:var(--ac-panel);color:var(--ac-accent) !important;border-color:var(--ac-line2);border-top-color:var(--ac-accent);border-bottom:2px solid var(--ac-panel);}
.ac-tab svg{width:16px;height:16px;}
.ac-pane{display:none;padding-top:10px;}
.ac-pane.sel{display:flex;flex-direction:column;gap:10px;}
.ac-pane .FormTable{margin:0 !important;}
.ac-pane .FormTable th{width:32%;}
/* buttons */
.ac-btn{display:inline-flex;align-items:center;justify-content:center;gap:6px;min-height:28px;padding:4px 12px;border-radius:3px;border:1px solid var(--ac-line2);background:var(--ac-deep);color:var(--ac-text) !important;font:12px Verdana,Arial,sans-serif;cursor:pointer;white-space:nowrap;}
.ac-btn:hover{border-color:var(--ac-accent);color:var(--ac-accent) !important;}
.ac-btn:disabled{opacity:.45;cursor:not-allowed;border-color:var(--ac-line2);color:var(--ac-text) !important;}
.ac-btn.primary{background:var(--ac-accent);border-color:var(--ac-accent);color:#1f2a2e !important;font-weight:bold;}
.ac-btn.primary:hover{background:#ffe066;color:#1f2a2e !important;}
.ac-btn.sel{border-color:var(--ac-accent);color:var(--ac-accent) !important;}
.ac-btnrow{display:flex;flex-wrap:wrap;gap:6px;align-items:center;}
/* segmented day / night */
.ac-segs{display:flex;gap:0;margin-bottom:12px;border:1px solid var(--ac-line2);border-radius:4px;overflow:hidden;width:max-content;max-width:100%;}
.ac-seg-btn{display:flex;align-items:center;gap:10px;padding:8px 14px;background:var(--ac-deep);border:0;border-right:1px solid var(--ac-line2);color:var(--ac-soft) !important;font:bold 12px Verdana,Arial,sans-serif;cursor:pointer;}
.ac-seg-btn:last-child{border-right:0;}
.ac-seg-btn.sel{background:var(--ac-accent);color:#1f2a2e !important;}
.ac-seg-btn input{font-size:11px;padding:2px 4px;}
/* animation editor */
.ac-ed{background:var(--ac-panel) !important;padding:14px !important;}
.ac-edbox{display:flex;flex-direction:column;gap:14px;}
.ac-head{display:flex;flex-direction:column;gap:14px;align-items:center;text-align:center;padding:16px 16px;border:1px solid var(--ac-line);border-radius:6px;background:var(--ac-inset);}
.ac-name{font-weight:bold;font-size:14px;color:var(--ac-text) !important;}
.ac-desc{font-size:12px;color:var(--ac-muted) !important;max-width:520px;margin-top:2px;}
.ac-bar{display:flex;gap:3px;padding:4px;background:#0b0f10;border-radius:12px;width:220px;max-width:100%;}
.ac-bar.tile{width:100%;padding:3px;gap:2px;border-radius:8px;}
.ac-bar.mini{width:72px;padding:2px;gap:2px;border-radius:6px;display:inline-flex;vertical-align:middle;}
.ac-seg{flex:1 1 0;height:14px;border-radius:7px;}
.ac-bar.tile .ac-seg{height:9px;border-radius:5px;}
.ac-bar.mini .ac-seg{height:8px;border-radius:4px;}
.ac-ctls{display:flex;flex-wrap:wrap;gap:28px;justify-content:center;align-items:flex-end;}
.ac-fld{display:flex;flex-direction:column;gap:6px;font-size:12px;color:var(--ac-soft) !important;}
.ac-row{display:flex;gap:8px;align-items:center;font-size:11px;color:var(--ac-muted) !important;}
.ac-swatch{width:32px;height:32px;padding:0;border:2px solid #8a9ca1;border-radius:50%;cursor:pointer;background:none;-webkit-appearance:none;appearance:none;overflow:hidden;}
.ac-swatch::-webkit-color-swatch-wrapper{padding:0;}
.ac-swatch::-webkit-color-swatch{border:none;border-radius:50%;}
.ac-swatch::-moz-color-swatch{border:none;border-radius:50%;}
.ac-fixed{display:inline-block;width:32px;height:32px;border-radius:50%;border:2px dashed #8a9ca1;}
.ac-cap{font-size:10px;color:var(--ac-muted) !important;text-align:center;}
.ac-rb{width:30px;height:30px;border-radius:50%;border:1px solid #b8c4c8;background:transparent;color:#fff;font-size:15px;cursor:pointer;}
.ac-rb:disabled{opacity:.35;cursor:not-allowed;}
.ac-dir{padding:6px 14px;border-radius:3px;border:1px solid var(--ac-accent);background:transparent;color:var(--ac-accent);font-size:14px;cursor:pointer;}
.ac-dir.sel{background:var(--ac-accent);color:#1f2a2e;}
.ac-pick{display:inline-flex;align-items:center;gap:8px;padding:9px 22px;border-radius:999px;border:2px solid transparent;color:#fff !important;font:bold 13px Verdana,Arial,sans-serif;cursor:pointer;background:linear-gradient(#24302f,#24302f) padding-box,linear-gradient(90deg,#ff0040,#ffcc00,#00e070,#00a0ff,#a000ff,#ff0040) border-box;background-size:100% 100%,300% 100%;animation:acglow 6s linear infinite;}
.ac-pick:hover{color:var(--ac-accent) !important;}
@keyframes acglow{from{background-position:0 0,0% 0}to{background-position:0 0,300% 0}}
.ac-note{font-size:12px;color:var(--ac-accent) !important;text-align:center;}
.ac-sub{display:flex;flex-direction:column;gap:8px;padding:12px 14px;border:1px solid var(--ac-line);border-radius:6px;background:var(--ac-inset);font-size:12px;color:var(--ac-soft) !important;}
.ac-sub-h{font-weight:bold;color:var(--ac-text) !important;}
.ac-sub input[type=number]{width:80px;}
.ac-tiles{display:none;flex-direction:column;gap:8px;padding:12px;border:1px solid var(--ac-line);border-radius:6px;background:var(--ac-deep);}
.ac-inbox{width:100%;padding-top:14px;border-top:1px solid var(--ac-line);}
.ac-head .ac-sub.ac-inbox{border:0;border-top:1px solid var(--ac-line);border-radius:0;background:transparent;padding:14px 0 0;text-align:left;align-items:center;}
.ac-head .ac-sub.ac-inbox .ac-help{text-align:center;}
.ac-tiles.open{display:flex;}
.ac-grp{font-size:11px;color:var(--ac-muted) !important;letter-spacing:.04em;}
.ac-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(92px,1fr));gap:8px;}
.ac-tile{display:flex;flex-direction:column;gap:6px;padding:7px;border-radius:4px;background:var(--ac-deep);border:1px solid var(--ac-line);color:#fff !important;font:11px/1.25 Verdana,Arial,sans-serif;cursor:pointer;text-align:left;min-width:0;}
.ac-tile:hover{border-color:var(--ac-accent);}
.ac-tile.sel{border:2px solid var(--ac-accent);padding:6px;}
.ac-tile:disabled{opacity:.35;cursor:not-allowed;}
.ac-tname{min-height:28px;color:#fff !important;}
.ac-badge{display:inline-block;align-self:flex-start;padding:1px 6px;border-radius:3px;font-size:10px !important;font-weight:bold;color:#1f2a2e !important;line-height:1.4;white-space:nowrap;}
.ac-sev-crit{background:#ff7a7a !important;}
.ac-sev-warn{background:#ffcc00 !important;}
.ac-sev-info{background:#9fd3e6 !important;}
.ac-cpu1{background:#9fd3e6 !important;}
.ac-cpu2{background:#ff9f7a !important;}
/* family colours */
.ac-fams{display:grid;grid-template-columns:repeat(8,1fr);gap:8px;padding:6px 0;}
.ac-fam{display:flex;flex-direction:column;align-items:center;gap:4px;min-width:0;font-size:11px;color:var(--ac-text) !important;text-align:center;}
.ac-fam input[type=text]{width:100%;max-width:84px;padding:2px 4px;border:1px solid var(--ac-line2);border-radius:3px;background:var(--ac-deep);color:#fff;font-size:11px;text-align:center;}
/* alert list */
.ac-list{display:flex;flex-direction:column;}
.ac-fhead{display:flex;align-items:center;gap:10px;width:100%;padding:9px 10px;background:#3a474b;border:0;border-top:1px solid var(--ac-line);color:#fff !important;font:bold 12px Verdana,Arial,sans-serif;cursor:pointer;text-align:left;}
.ac-fhead:hover{background:#435257;}
.ac-fhead .ac-count{margin-left:auto;font-weight:normal;font-size:11px;color:var(--ac-muted) !important;}
.ac-arow{display:grid;grid-template-columns:62px 1fr 160px auto;gap:12px;align-items:center;padding:9px 10px;border-top:1px solid var(--ac-line);}
.ac-arow.off .ac-aname, .ac-arow.off .ac-asum{opacity:.55;}
.ac-aname{display:flex;align-items:center;gap:8px;flex-wrap:wrap;font-weight:bold;font-size:12px;color:var(--ac-text) !important;}
.ac-asum{font-size:11px;color:var(--ac-muted) !important;margin-top:3px;}
.ac-live{font-size:10px;font-weight:bold;color:var(--ac-bad) !important;}
.ac-aedit{padding:14px;background:var(--ac-inset);border-top:1px solid var(--ac-line);}
.ac-aedit .ac-desc{margin:0 0 12px;max-width:none;text-align:left;}
.ac-aopts{display:flex;flex-wrap:wrap;gap:24px;margin-bottom:14px;}
/* footer */
.ac-foot{display:flex;flex-direction:column;align-items:center;gap:10px;margin-top:16px;padding-top:14px;border-top:1px solid var(--ac-line2);}
.ac-confirm{display:flex;flex-wrap:wrap;align-items:center;gap:8px;padding:8px 12px;border:1px solid var(--ac-accent);border-radius:4px;background:var(--ac-deep);font-size:12px;color:var(--ac-soft) !important;}
.ac-credit{font-size:10px;color:var(--ac-muted) !important;}
.ac-log{font-family:monospace;font-size:11px;white-space:pre-wrap;background:#2F3A3E;padding:6px;max-height:220px;overflow:auto;color:var(--ac-soft);}
/* one notice for the whole page */
.ac-toast{position:fixed;left:50%;bottom:24px;transform:translateX(-50%);z-index:10000;display:none;align-items:center;gap:14px;max-width:560px;padding:10px 16px;border-radius:6px;background:#1f2a2e;border:1px solid #6b7f84;border-left:5px solid #9fd3e6;color:#fff !important;font-size:13px;box-shadow:0 4px 18px rgba(0,0,0,.5);}
.ac-toast.show{display:flex;}
.ac-toast.ok{border-left-color:#8BC34A;}
.ac-toast.err{border-left-color:#FF5252;}
.ac-toast button{background:transparent;border:0;color:#b8c4c8;font-size:16px;cursor:pointer;}
.ac-toast .ac-tt{color:#fff !important;}
/* previews of the effects */
.fx-breath{animation:acbreathe 3s ease-in-out infinite}
.fx-flash{animation:acflash 1s steps(1,end) infinite}
.fx-run{animation:acrun 1.2s ease-in-out infinite}
.fx-comet{animation:accomet 1.6s linear infinite}
.fx-siren{animation:acsiren 1.2s linear infinite}
.fx-siren2{animation:acsiren2 1s linear infinite}
.fx-starry{animation:actwinkle 2.2s steps(1,end) infinite}
.fx-cycle{animation:achue 6s linear infinite}
.fx-heart{animation:acheart 1.3s ease-out infinite}
.fx-candle{animation:accandle 2.5s linear infinite}
@keyframes acbreathe{0%,100%{opacity:.12}50%{opacity:1}}
@keyframes acflash{0%{opacity:1}50%{opacity:.05}}
@keyframes acrun{0%,100%{opacity:.08}18%{opacity:1}40%{opacity:.08}}
@keyframes accomet{0%{opacity:1}35%{opacity:.35}60%,100%{opacity:.05}}
@keyframes acsiren{0%,9%{opacity:1}9.5%,19%{opacity:.05}19.5%,28%{opacity:1}28.5%,100%{opacity:.05}}
@keyframes acsiren2{0%,7%{opacity:1}8.3%,15%{opacity:.05}16.6%,23%{opacity:1}25%,32%{opacity:.05}33.3%,40%{opacity:1}41.6%,100%{opacity:.05}}
@keyframes actwinkle{0%{opacity:.35}20%{opacity:.9}35%{opacity:.25}55%{opacity:1}70%{opacity:.4}85%{opacity:.75}}
@keyframes achue{from{filter:hue-rotate(0deg)}to{filter:hue-rotate(360deg)}}
@keyframes acheart{0%{opacity:.15}8%{opacity:1}16%{opacity:.35}24%{opacity:1}40%,100%{opacity:.15}}
@keyframes accandle{0%{opacity:.85}10%{opacity:.6}20%{opacity:.95}35%{opacity:.7}50%{opacity:1}62%{opacity:.65}75%{opacity:.9}88%{opacity:.72}100%{opacity:.85}}
@media (prefers-reduced-motion: reduce){.ac-seg,.ac-pick{animation:none !important;}}
</style>
<script>
var custom_settings = <% get_custom_settings(); %>;
var ac_thisPage = location.pathname.split('/').pop();

/* ------------------------------------------------------------ catalogue (same as aura-ctrl.sh) */
// d = seconds per cycle at normal speed; mv = runs across the zones; rnd = zones out of step; alt = two colours in turn
var AC_ANIMS = [
	{id:'off',name:'Off',grp:'r',cpu:0,cmin:0,cmax:0,fx:'',help:'The logo is off.'},
	{id:'static',name:'Static',grp:'r',cpu:0,cmin:1,cmax:1,fx:'',help:'One steady colour.'},
	{id:'breath',name:'Breathing',grp:'r',cpu:0,cmin:1,cmax:1,fx:'fx-breath',d:3,help:'Fades in and out.'},
	{id:'flash',name:'Flash',grp:'r',cpu:0,cmin:1,cmax:1,fx:'fx-flash',d:1,help:'Blinks on and off.'},
	{id:'pulse',name:'Pulse',grp:'r',cpu:0,cmin:1,cmax:1,fx:'fx-run',d:1.2,mv:1,help:'A quick soft pulse runs from left to right.'},
	{id:'siren',name:'Siren',grp:'r',cpu:0,cmin:1,cmax:1,fx:'fx-siren',d:1,mv:1,help:'Double blink running from left to right, like an emergency light.'},
	{id:'comet',name:'Comet',grp:'r',cpu:0,cmin:1,cmax:1,fx:'fx-comet',d:1.6,mv:1,dir:true,help:'A light with a tail runs across the logo.'},
	{id:'wave',name:'Wave',grp:'r',cpu:0,cmin:1,cmax:1,fx:'fx-breath',d:2.4,mv:1,dir:true,help:'A soft wave runs across the logo.'},
	{id:'yoyo',name:'Glowing Yoyo',grp:'r',cpu:0,cmin:1,cmax:1,fx:'fx-breath',d:2.4,help:'Glows up and down.'},
	{id:'starry',name:'Starry Night',grp:'r',cpu:0,cmin:1,cmax:1,fx:'fx-starry',d:2.2,rnd:1,help:'Random twinkle.'},
	{id:'cycle',name:'Color Cycle',grp:'r',cpu:0,cmin:0,cmax:0,fx:'fx-cycle',d:6,help:'Cycles through all colours. The router chooses the colours.'},
	{id:'rainbow',name:'Rainbow',grp:'r',cpu:0,cmin:0,cmax:0,fx:'fx-cycle',d:3,mv:1,dir:true,help:'A rainbow runs across the logo. The router chooses the colours.'},
	{id:'strobe',name:'Strobing',grp:'r',cpu:0,cmin:0,cmax:0,fx:'fx-cycle',d:3,help:'Fades in and out changing colour. The router chooses the colours.'},
	{id:'sirenmc',name:'Siren multicolor',grp:'r',cpu:0,cmin:0,cmax:0,fx:'fx-siren fx-cycle',d:1,mv:1,help:'Siren with changing colours. The router chooses the colours.'},
	{id:'multi',name:'Multi-colour',grp:'a',cpu:0,cmin:2,cmax:3,fx:'',fixedSpeed:true,help:'Your colours are spread across the light zones of the logo. The result depends on the router model.'},
	{id:'steps',name:'Colour steps',grp:'a',cpu:1,cmin:2,cmax:3,fx:'fx-breath',d:5,help:'Shows each colour in turn, with a short fade through black.'},
	{id:'traffic',name:'Traffic meter',grp:'a',cpu:1,cmin:3,cmax:3,fx:'',fixedSpeed:true,sceneOnly:true,caps:['Low','Medium','High'],help:'A bar meter of the internet traffic: three zones always on, each from dim to full as the traffic fills its third of the line. On models without a known zone map: one colour that changes from the first to the last.'},
	{id:'fade',name:'Colour fade',grp:'a',cpu:2,cmin:2,cmax:3,fx:'',fb:'steps',help:'Blends smoothly from one colour to the next.'},
	{id:'cbreath',name:'Colour breathing',grp:'a',cpu:2,cmin:2,cmax:3,fx:'fx-breath',d:3,fb:'breath',help:'Breathes, with a new colour at each breath.'},
	{id:'alt',name:'Alternate',grp:'a',cpu:2,cmin:2,cmax:2,fx:'fx-flash',d:1,alt:1,fb:'flash',help:'Switches between two colours, like a police light.'},
	{id:'siren2',name:'Two-colour siren',grp:'a',cpu:2,cmin:2,cmax:2,fx:'fx-siren2',d:1,alt:1,fb:'siren',help:'Fast flashes in turn, like an emergency vehicle: some light zones in the first colour, the others in the second.'},
	{id:'heart',name:'Heartbeat',grp:'a',cpu:2,cmin:1,cmax:1,fx:'fx-heart',d:1.3,fb:'breath',help:'Double beat, then a pause.'},
	{id:'candle',name:'Candle',grp:'a',cpu:2,cmin:1,cmax:1,fx:'fx-candle',d:2.5,rnd:1,fb:'starry',help:'Flickers like a candle.'},
	{id:'sweep',name:'Sweep',grp:'a',cpu:2,cmin:2,cmax:3,fx:'',dir:true,fb:'multi',help:'Your colours move across the light zones of the logo. The result depends on the router model.'}
];
var AC_TRAFFIC_DEF = ['00ff00', 'ffc800', 'ff0000'];
var AC_SPEEDTXT = ['Slowest', 'Slow', 'Normal', 'Fast', 'Fastest'];
var AC_SPEEDF = [2, 1.5, 1, 0.75, 0.5];
var AC_FAM_NAMES = ['Security', 'Connectivity', 'Wi-Fi', 'System', 'Maintenance', 'Activity'];
var AC_FAM_DEF = 'ff0000,ff3000,a000ff,ffc800,00a0ff,ffffff,00ff40,ff40c0';
var AC_SEV = {crit:'Critical', warn:'Warning', info:'Info'};
var AC_DUR = [['active', 'While active'], ['5', '5 minutes'], ['10', '10 minutes'], ['30', '30 minutes'], ['ack', 'Until acknowledged']];
var AC_SCENE_DEF = 'static:2:0:1:0800ff:ffffff:00a0ff';
var AC_CAL = [['ffffff', 'White'], ['ffc800', 'Yellow'], ['ff3000', 'Orange'], ['a000ff', 'Violet'], ['00a0ff', 'Light blue']];
// id, name, family index, severity, default config (on:duration:night:source:look), description
var AC_ALERTS = [
	['tamper', 'Router tampering', 0, 'crit', '1:ack:1:fam:siren:2:0:1:ff0000:ffffff:00a0ff', 'Critical settings changed (DNS, remote access, port forwarding, admin), or /jffs/scripts or the scheduled jobs changed. Acknowledge accepts the new configuration.'],
	['eviltwin', 'Evil twin detected', 0, 'crit', '1:ack:1:fam:siren:2:0:1:ff0000:ffffff:00a0ff', 'A nearby access point broadcasts one of your network names with an address that is not this router or one of its AiMesh nodes.'],
	['wan', 'Internet down', 1, 'crit', '1:active:1:fam:siren:2:0:1:ff3000:ffffff:00a0ff', 'The WAN connection is down.'],
	['prot', 'Protection stalled (Skynet)', 0, 'warn', '1:active:0:fam:flash:2:0:1:ff0000:ffffff:00a0ff', 'Skynet is installed but its block list is not loaded, or its malware lists were not updated for 48 hours.'],
	['newdev', 'Unknown device', 0, 'warn', '1:ack:0:fam:flash:2:0:1:ff0000:ffffff:00a0ff', 'A device never seen before got an address from the router. Acknowledge adds it to the known devices.'],
	['radar', 'Radar detected (ZW-DFS)', 2, 'warn', '1:30:0:fam:flash:2:0:1:a000ff:ffffff:00a0ff', 'ZW-DFS logged a radar event on a DFS channel. Needs the ZW-DFS add-on.'],
	['temp', 'High temperature', 3, 'warn', '1:active:1:fam:flash:2:0:1:ffc800:ffffff:00a0ff', 'The CPU temperature is over 90 \u00b0C.'],
	['usb', 'USB missing or almost full', 3, 'warn', '1:active:0:fam:flash:2:0:1:ffc800:ffffff:00a0ff', 'A USB disk mounted at start-up is gone, or a USB disk is more than 90% full.'],
	['cac', 'Radar check in progress (ZW-DFS)', 2, 'info', '1:active:0:fam:pulse:2:0:1:a000ff:ffffff:00a0ff', 'ZW-DFS is running a background radar check or moving the 5 GHz radio. Needs the ZW-DFS add-on.'],
	['fw', 'Firmware update available', 4, 'info', '1:active:0:fam:breath:0:0:1:00a0ff:ffffff:00a0ff', 'The router found a new firmware version.'],
	['admin', 'Admin session active', 5, 'info', '1:active:0:fam:pulse:1:0:1:ffffff:ffffff:00a0ff', 'Someone is logged in to the router web page or SSH.']
];
var AC_ICONS = {
	lighting: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9 18h6"/><path d="M10 22h4"/><path d="M12 2a7 7 0 0 0-4 12.7c.6.5 1 1.2 1 2V18h6v-1.3c0-.8.4-1.5 1-2A7 7 0 0 0 12 2z"/></svg>',
	alerts: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.9 1.9 0 0 0 3.4 0"/></svg>',
	diagnostics: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 12h4l3-8 4 16 3-8h4"/></svg>'
};

/* ------------------------------------------------------------ helpers */
function ac_el(id){ return document.getElementById(id); }
function ac_esc(s){ return String(s == null ? '' : s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
function ac_anim(id){ for (var i = 0; i < AC_ANIMS.length; i++) if (AC_ANIMS[i].id == id) return AC_ANIMS[i]; return AC_ANIMS[1]; }
function ac_cs(k, d){ var v = custom_settings[k]; return (v == null || v === '') ? d : String(v); }
function ac_alertDef(id){ for (var i = 0; i < AC_ALERTS.length; i++) if (AC_ALERTS[i][0] == id) return AC_ALERTS[i]; return null; }
function ac_clean(s){ return String(s).replace(/[|:,"\\<>]/g, ' ').replace(/^\s+|\s+$/g, '').substring(0, 20); }
function ac_pct(v, min){ v = parseInt(v, 10); return (v >= (min || 20) && v <= 100) ? v : 100; }
function ac_pad3(n){ return ('00' + n).slice(-3); }
function ac_switch(on, onclick, label){ return '<button type="button" class="ac-sw ' + (on ? 'on' : 'off') + '" role="switch" aria-checked="' + (on ? 'true' : 'false') + '"' + (label ? ' aria-label="' + ac_esc(label) + '"' : '') + ' onclick="' + onclick + '">' + (on ? 'ON' : 'OFF') + '<span class="knob"></span></button>'; }
function ac_table(title, body, right){ return '<table width="100%" border="1" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable"><thead><tr><td colspan="2">' + title + (right ? '<span style="float:right;font-weight:normal;">' + right + '</span>' : '') + '</td></tr></thead>' + body + '</table>'; }
// a setting row: label, control, help below the control
function ac_rowh(label, control, help){ return '<tr><th>' + label + '</th><td>' + control + (help ? '<span class="ac-help">' + help + '</span>' : '') + '</td></tr>'; }

// look string <-> object
function ac_parseLook(s){
	var p = String(s).split(':');
	var l = {anim: p[0] || 'static', speed: parseInt(p[1], 10), dir: parseInt(p[2], 10), n: parseInt(p[3], 10), c: [p[4] || '0800ff', p[5] || 'ffffff', p[6] || '00a0ff']};
	if (isNaN(l.speed)) l.speed = 2; if (isNaN(l.dir)) l.dir = 0; if (isNaN(l.n)) l.n = 1;
	if (l.anim == 'traffic' && l.n < 3) { l.c = AC_TRAFFIC_DEF.slice(); l.n = 3; }
	return ac_fixLook(l);
}
function ac_fixLook(l){ var a = ac_anim(l.anim); l.n = a.cmax == 0 ? 0 : Math.max(a.cmin, Math.min(a.cmax, l.n || a.cmin)); return l; }
function ac_lookStr(l){ return [l.anim, l.speed, l.dir, l.n, l.c[0], l.c[1], l.c[2]].join(':'); }

/* ------------------------------------------------------------ settings */
var AC = {};
function ac_load(){
	AC.aura = ac_cs('auractrl_aura', '1');
	AC.alerts = ac_cs('auractrl_alerts', '1');
	var o = ac_cs('auractrl_opts', '1,0,1').split(',');
	AC.smooth = o[0] == '1'; AC.eco = o[1] == '1'; AC.multi = o[2] == '1';
	var br = ac_cs('auractrl_bright', '100,100').split(',');
	AC.bright = [ac_pct(br[0], 10), ac_pct(br[1], 10)];
	AC.dn = ac_cs('auractrl_dn', '0') == '1';
	var t = ac_cs('auractrl_times', '07:00,23:00').split(',');
	AC.dayStart = t[0] || '07:00'; AC.nightStart = t[1] || '23:00';
	AC.day = ac_parseLook(ac_cs('auractrl_day', AC_SCENE_DEF));
	AC.night = ac_parseLook(ac_cs('auractrl_night', AC_SCENE_DEF));
	AC.fam = ac_cs('auractrl_fam', AC_FAM_DEF).split(',');
	var cn = ac_cs('auractrl_cn', 'Custom 1|Custom 2').split('|');
	AC.cname = [cn[0] || 'Custom 1', cn[1] || 'Custom 2'];
	AC.zones = ac_cs('auractrl_zones', 'none');
	var co = ac_cs('auractrl_corr', '').split(',');
	AC.corr = co.length == 3 ? [ac_pct(co[0]), ac_pct(co[1]), ac_pct(co[2])] : null;
	// line speed in Mbps: "down,up" ("manual,down,up" from earlier drafts)
	var tr = ac_cs('auractrl_traffic', '').split(',');
	if (tr[0] == 'manual') tr.shift();
	AC.traffic = {down: parseInt(tr[0], 10) || 0, up: parseInt(tr[1], 10) || 0};
	AC.trate = ac_cs('auractrl_trate', '5');
	if (AC.trate != '3' && AC.trate != '10') AC.trate = '5';
	AC.al = {};
	for (var i = 0; i < AC_ALERTS.length; i++) {
		var d = AC_ALERTS[i], p = ac_cs('auractrl_a_' + d[0], d[4]).split(':');
		AC.al[d[0]] = {on: p[0] == '1', dur: p[1], night: p[2] == '1', src: p[3], look: ac_parseLook(p.slice(4).join(':'))};
	}
}
function ac_settings(){
	var s = {
		auractrl_aura: AC.aura, auractrl_alerts: AC.alerts,
		auractrl_opts: [AC.smooth ? 1 : 0, AC.eco ? 1 : 0, AC.multi ? 1 : 0].join(','),
		auractrl_bright: AC.bright.join(','),
		auractrl_dn: AC.dn ? '1' : '0', auractrl_times: AC.dayStart + ',' + AC.nightStart,
		auractrl_day: ac_lookStr(AC.day), auractrl_night: ac_lookStr(AC.night),
		auractrl_fam: AC.fam.join(','), auractrl_cn: ac_clean(AC.cname[0]) + '|' + ac_clean(AC.cname[1]),
		auractrl_zones: AC.zones,
		auractrl_corr: AC.corr ? AC.corr.join(',') : '',
		auractrl_traffic: (AC.traffic.down > 0 && AC.traffic.up > 0) ? AC.traffic.down + ',' + AC.traffic.up : '',
		auractrl_trate: AC.trate
	};
	for (var i = 0; i < AC_ALERTS.length; i++) {
		var id = AC_ALERTS[i][0], a = AC.al[id];
		s['auractrl_a_' + id] = [a.on ? 1 : 0, a.dur, a.night ? 1 : 0, a.src, ac_lookStr(a.look)].join(':');
	}
	return s;
}
function ac_dirty(){
	var s = ac_settings();
	for (var k in s) { var v = custom_settings[k]; if ((v == null ? '' : String(v)) != s[k]) return true; }
	return false;
}
// colour correction shown: the user's, else the model's (from the router status)
function ac_corrNow(){
	if (AC.corr) return AC.corr;
	var s = window.auractrl_status, m = (s && s.corr_model ? s.corr_model : '100,100,100').split(',');
	return [ac_pct(m[0]), ac_pct(m[1]), ac_pct(m[2])];
}
function ac_trafficSet(){ return AC.traffic.down > 0 && AC.traffic.up > 0; }

/* ------------------------------------------------------------ previews */
function ac_i2c(){ var s = window.auractrl_status; return !s || s.i2c == '1'; }
function ac_effective(look){ var a = ac_anim(look.anim); if (a.cpu == 2 && (AC.eco || !ac_i2c())) return ac_anim(a.fb); if (a.id == 'multi' && !ac_i2c()) return ac_anim('static'); return a; }
// logo preview: 3 zones in a dark bar; size '' (editor), 'tile' or 'mini'. Effects that run across the logo
// get a delay per zone (direction from the look); the cycle follows the speed.
function ac_preview(look, size){
	var a = ac_effective(look), c = look.c, segs = '', i, col, st, d, k;
	d = (a.d || 1.2) * (a.fixedSpeed ? 1 : AC_SPEEDF[look.speed == null ? 2 : look.speed]);
	for (i = 0; i < 3; i++) {
		st = '';
		if (a.id == 'off') col = '#2a2f31';
		else if (a.id == 'traffic') { col = '#' + (c[i] || AC_TRAFFIC_DEF[i]); st = ';opacity:' + [1, 0.55, 0.3][i]; }
		else if (a.cmax == 0) col = ['#ff0040', '#00e070', '#00a0ff'][i];
		else if (a.id == 'multi' || a.id == 'sweep') col = '#' + c[Math.min(i, Math.max(look.n, 1) - 1)];
		else if (a.alt) col = '#' + c[i == 1 ? 1 : 0];
		else col = '#' + c[0];
		st = 'background:' + col + st;
		if (a.fx) {
			k = (a.dir && look.dir == 1) ? 2 - i : i;
			st += ';animation-duration:' + d.toFixed(2) + 's';
			if (a.mv) st += ';animation-delay:' + (-(3 - k) * d / 4).toFixed(2) + 's';
			else if (a.rnd) st += ';animation-delay:' + (-[0, 0.7, 1.5][i] * d / 2.2).toFixed(2) + 's';
			else if (a.alt && i == 1) st += ';animation-delay:' + (-d / 2).toFixed(2) + 's';
		}
		segs += '<div class="ac-seg ' + a.fx + '" style="' + st + '"></div>';
	}
	return '<div class="ac-bar' + (size ? ' ' + size : '') + '" aria-hidden="true">' + segs + '</div>';
}

/* ------------------------------------------------------------ animation editor (scenes and alerts) */
// key: 'day', 'night' or 'a_<alert id>'
var ac_openTiles = {};
function ac_lookOf(key){ return key.indexOf('a_') == 0 ? AC.al[key.substring(2)].look : AC[key]; }
function ac_srcColour(key){
	var id = key.substring(2), a = AC.al[id], d = ac_alertDef(id);
	if (a.src == 'fam') return AC.fam[d[2]]; if (a.src == 'c1') return AC.fam[6]; if (a.src == 'c2') return AC.fam[7]; return a.look.c[0];
}
function ac_editor(key, sceneOnly){
	var l = ac_lookOf(key), a = ac_anim(l.anim), eff = ac_effective(l), h = '<div class="ac-edbox">', i, ctl = '';
	var src = key.indexOf('a_') == 0 ? AC.al[key.substring(2)].src : 'own';
	var pl = {anim: l.anim, n: l.n, c: [src == 'own' ? l.c[0] : ac_srcColour(key), l.c[1], l.c[2]], speed: l.speed, dir: l.dir};
	var open = !!ac_openTiles[key];
	// one box for the animation in use: preview, name, description and all its options
	h += '<div class="ac-head">' + ac_preview(pl) +
		'<div><div class="ac-name">' + ac_esc(a.name) + '</div><div class="ac-desc">' + ac_esc(a.help) + '</div></div>';
	if (eff.id != a.id) h += '<div class="ac-note">' + (AC.eco ? 'Eco mode is on: ' : 'Not available on this router: ') + ac_esc(a.name) + ' is shown as ' + ac_esc(eff.name) + '.</div>';
	if (a.cmax > 0) {
		ctl += '<div class="ac-fld">' + (a.caps ? 'Colours of the bars' : 'Colours') + '<div class="ac-row">';
		for (i = 0; i < l.n; i++) {
			var sw;
			if (i == 0 && src != 'own') sw = '<span class="ac-fixed" title="First colour: ' + ac_esc(src == 'fam' ? 'family colour' : AC.cname[src == 'c1' ? 0 : 1]) + '" style="background:#' + ac_srcColour(key) + '"></span>';
			else sw = '<input type="color" class="ac-swatch" value="#' + l.c[i] + '" onchange="ac_setColour(\'' + key + '\',' + i + ',this.value)" aria-label="' + (a.caps ? a.caps[i] + ' traffic colour' : 'Colour ' + (i + 1)) + '">';
			ctl += a.caps ? '<span style="display:flex;flex-direction:column;align-items:center;gap:3px;">' + sw + '<span class="ac-cap">' + a.caps[i] + '</span></span>' : sw;
		}
		if (a.cmax > a.cmin) ctl += '<button type="button" class="ac-rb" onclick="ac_count(\'' + key + '\',-1)"' + (l.n <= a.cmin ? ' disabled' : '') + ' aria-label="Remove a colour">&minus;</button><button type="button" class="ac-rb" onclick="ac_count(\'' + key + '\',1)"' + (l.n >= a.cmax ? ' disabled' : '') + ' aria-label="Add a colour">+</button>';
		if (a.caps) ctl += '<button type="button" class="ac-btn" onclick="ac_trafficColours(\'' + key + '\')">Default colours</button>';
		ctl += '</div></div>';
	}
	if (!a.fixedSpeed && a.id != 'off' && a.id != 'static')
		ctl += '<div class="ac-fld" style="min-width:220px;">Speed: ' + AC_SPEEDTXT[l.speed] + '<div class="ac-row">Slow <input type="range" min="0" max="4" step="1" value="' + l.speed + '" onchange="ac_setSpeed(\'' + key + '\',this.value)" style="width:130px;" aria-label="Speed"> Fast</div></div>';
	if (a.dir) ctl += '<div class="ac-fld">Direction<div class="ac-row"><button type="button" class="ac-dir' + (l.dir == 1 ? ' sel' : '') + '" onclick="ac_setDir(\'' + key + '\',1)" aria-label="Right to left">&larr;</button><button type="button" class="ac-dir' + (l.dir == 0 ? ' sel' : '') + '" onclick="ac_setDir(\'' + key + '\',0)" aria-label="Left to right">&rarr;</button></div></div>';
	if (ctl) h += '<div class="ac-ctls ac-inbox">' + ctl + '</div>';
	if (a.id == 'traffic') {
		var t = AC.traffic;
		h += '<div class="ac-sub ac-inbox"><div class="ac-sub-h">Speed of your internet line</div>' +
			'<div class="ac-row" style="font-size:12px;color:#d3dcdf;flex-wrap:wrap;gap:14px;">' +
			'<label>Download <input type="number" min="1" max="100000" class="input_6_table" value="' + (t.down || '') + '" onchange="AC.traffic.down=parseInt(this.value,10)||0;ac_render();"> Mbps</label>' +
			'<label>Upload <input type="number" min="1" max="100000" class="input_6_table" value="' + (t.up || '') + '" onchange="AC.traffic.up=parseInt(this.value,10)||0;ac_render();"> Mbps</label>' +
			'<label>Update every <select class="input_option" onchange="AC.trate=this.value;ac_render();">' +
			'<option value="3"' + (AC.trate == '3' ? ' selected' : '') + '>3 seconds</option><option value="5"' + (AC.trate == '5' ? ' selected' : '') + '>5 seconds</option><option value="10"' + (AC.trate == '10' ? ' selected' : '') + '>10 seconds</option></select></label></div>' +
			'<span class="ac-help" style="margin:0;">Run a speed test (for example on speedtest.net, from a computer connected by cable, with no other traffic) and enter the results. Download and upload are measured separately; the busier one moves the meter. The measure is light at any interval: 3 seconds reacts fastest.</span>' +
			(ac_trafficSet() ? '' : '<span class="ac-warn" style="font-size:11px;">Enter both speeds: until then the meter stays at rest.</span>') + '</div>';
	}
	h += '</div>';
	// below the box: the button, and the list of animations right under it
	h += '<div style="text-align:center;"><button type="button" class="ac-pick" onclick="ac_toggleTiles(\'' + key + '\')" aria-expanded="' + open + '">&#10022; Choose an animation ' + (open ? '&#9652;' : '&#9662;') + '</button></div>';
	h += '<div id="tiles_' + key + '" class="ac-tiles' + (open ? ' open' : '') + '">' + ac_tiles(key, sceneOnly) + '</div>';
	return h + '</div>';
}
function ac_tiles(key, sceneOnly){
	var l = ac_lookOf(key), h = '', g, i, a, badge, dis, pl;
	for (g = 0; g < 2; g++) {
		h += '<div class="ac-grp">' + (g == 0 ? 'ROUTER EFFECTS &middot; run by the light controller, no CPU' : 'AURA-CTRL ANIMATIONS &middot; made by the add-on') + '</div><div class="ac-grid">';
		for (i = 0; i < AC_ANIMS.length; i++) {
			a = AC_ANIMS[i];
			if ((g == 0) != (a.grp == 'r')) continue;
			if (a.sceneOnly && !sceneOnly) continue;
			dis = AC.eco && a.cpu == 2;
			badge = a.cpu == 1 ? '<span class="ac-badge ac-cpu1">Low CPU</span>' : (a.cpu == 2 ? '<span class="ac-badge ac-cpu2">High CPU</span>' : '');
			pl = {anim: a.id, n: a.cmax == 0 ? 0 : Math.max(a.cmin, Math.min(a.cmax, Math.max(l.n, a.cmin))), c: a.id == 'traffic' ? AC_TRAFFIC_DEF : l.c, speed: 2, dir: 0};
			h += '<button type="button" class="ac-tile' + (a.id == l.anim ? ' sel' : '') + '"' + (dis ? ' disabled' : '') + ' title="' + ac_esc(dis ? a.name + ' is not available in Eco mode' : a.name + ': ' + a.help) + '" onclick="ac_setAnim(\'' + key + '\',\'' + a.id + '\')">' +
				ac_preview(pl, 'tile') + '<span class="ac-tname">' + ac_esc(a.name) + '</span>' + badge + '</button>';
		}
		h += '</div>';
	}
	return h;
}
function ac_toggleTiles(key){
	ac_openTiles[key] = !ac_openTiles[key]; ac_render();
	// bring the opened list into view
	var t = ac_el('tiles_' + key);
	if (ac_openTiles[key] && t && t.scrollIntoView) { try { t.scrollIntoView({behavior: 'smooth', block: 'nearest'}); } catch (e) { t.scrollIntoView(false); } }
}
function ac_setAnim(key, id){
	var l = ac_lookOf(key);
	if (id == 'traffic' && l.anim != 'traffic') l.c = AC_TRAFFIC_DEF.slice();
	l.anim = id; ac_fixLook(l); ac_openTiles[key] = false; ac_render();
}
function ac_trafficColours(key){ ac_lookOf(key).c = AC_TRAFFIC_DEF.slice(); ac_render(); }
function ac_setColour(key, i, v){ ac_lookOf(key).c[i] = v.replace('#', '').toLowerCase(); ac_render(); }
function ac_count(key, d){ var l = ac_lookOf(key); l.n += d; ac_fixLook(l); ac_render(); }
function ac_setSpeed(key, v){ ac_lookOf(key).speed = parseInt(v, 10); ac_render(); }
function ac_setDir(key, v){ ac_lookOf(key).dir = v; ac_render(); }

/* ------------------------------------------------------------ rendering */
var ac_tab = 'lighting', ac_scene = 'day', ac_editing = {}, ac_openFam = {0: true}, ac_restoreAsk = false, ac_identSec = 5;
function ac_render(){
	ac_el('ac_aura').innerHTML = ac_switch(AC.aura == '1', 'ac_auraToggle()', 'Aura RGB');
	var tabs = [['lighting', 'Lighting'], ['alerts', 'Alerts'], ['diagnostics', 'Diagnostics']], h = '', i;
	for (i = 0; i < tabs.length; i++)
		h += '<button type="button" role="tab" aria-selected="' + (ac_tab == tabs[i][0]) + '" class="ac-tab' + (ac_tab == tabs[i][0] ? ' sel' : '') + '" onclick="ac_selTab(\'' + tabs[i][0] + '\')">' + AC_ICONS[tabs[i][0]] + tabs[i][1] + '</button>';
	ac_el('ac_tabs').innerHTML = h;
	for (i = 0; i < tabs.length; i++) ac_el('pane_' + tabs[i][0]).className = 'ac-pane' + (ac_tab == tabs[i][0] ? ' sel' : '');
	ac_renderLighting(); ac_renderAlerts(); ac_renderDiag(); ac_renderFoot();
}
function ac_opt(id){ AC[id] = !AC[id]; ac_render(); }

function ac_renderLighting(){
	var h = '', body;
	// scene
	body = ac_rowh('Separate day and night scenes', ac_switch(AC.dn, "ac_opt('dn')", 'Separate day and night scenes'),
		'A day scene and a night scene, each with its start time. The night also hides the alerts that are not shown at night.');
	var ed = '';
	if (AC.dn) {
		if (ac_scene != 'night') ac_scene = 'day';
		ed += '<div class="ac-segs" role="tablist">' +
			'<button type="button" class="ac-seg-btn' + (ac_scene == 'day' ? ' sel' : '') + '" onclick="ac_scene=\'day\';ac_render();">Day <input type="time" class="input_6_table" value="' + AC.dayStart + '" onclick="event.stopPropagation()" onchange="AC.dayStart=this.value||\'07:00\'" aria-label="Day starts at"></button>' +
			'<button type="button" class="ac-seg-btn' + (ac_scene == 'night' ? ' sel' : '') + '" onclick="ac_scene=\'night\';ac_render();">Night <input type="time" class="input_6_table" value="' + AC.nightStart + '" onclick="event.stopPropagation()" onchange="AC.nightStart=this.value||\'23:00\'" aria-label="Night starts at"></button></div>';
		ed += ac_editor(ac_scene, true);
	} else ed += ac_editor('day', true);
	body += '<tr><td colspan="2" class="ac-ed">' + ed + '</td></tr>';
	h += ac_table('Scene <span style="font-weight:normal;">&middot; shown when no alert is active</span>', body);
	// options
	body = ac_brightRow(0, AC.dn ? 'Day brightness' : 'Brightness');
	if (AC.dn) body += ac_brightRow(1, 'Night brightness');
	body += ac_rowh('Smooth transitions', ac_switch(AC.smooth, "ac_opt('smooth')", 'Smooth transitions'),
		'When the logo changes, it fades through black for about 1 second. Off: the change is instant, with a short flash of the previous colour.' + (ac_i2c() ? '' : ' Not available on this router.'));
	body += ac_rowh('Eco mode', ac_switch(AC.eco, "ac_opt('eco')", 'Eco mode'),
		'Turns off the animations marked High CPU, for the scene and for the alerts, and shows the closest router effect instead.');
	h += ac_table('Lighting options', body);
	ac_el('pane_lighting').innerHTML = h;
}
// brightness of the logo, 10-100%: scene and alerts (tests always use full brightness)
function ac_brightRow(i, title){
	return ac_rowh(title, '<input type="range" id="ac_bright' + i + '" min="10" max="100" step="5" value="' + AC.bright[i] + '" style="width:220px;vertical-align:middle;" aria-label="' + title + '"' +
		' oninput="ac_el(\'ac_brightv' + i + '\').innerHTML=this.value+\'%\';" onchange="AC.bright[' + i + ']=ac_pct(this.value,10);ac_render();"> <b id="ac_brightv' + i + '">' + AC.bright[i] + '%</b>',
		i == 1 ? 'From the start of the night scene: lower it to keep the logo discreet at night.' : (AC.dn ? 'From the start of the day scene.' : 'Applies to the scene and to the alerts.'));
}

function ac_signalText(id){
	var a = AC.al[id], eff = ac_effective(a.look), src;
	if (eff.cmax == 0) src = 'router colours';
	else if (a.src == 'fam') src = 'family colour'; else if (a.src == 'own') src = 'own colour'; else src = AC.cname[a.src == 'c1' ? 0 : 1];
	return eff.name + ' &middot; ' + ac_esc(src) + ' &middot; ' + ac_durText(a.dur) + (AC.dn ? ' &middot; ' + (a.night ? 'shown at night' : 'hidden at night') : '');
}
function ac_durText(d){ for (var i = 0; i < AC_DUR.length; i++) if (AC_DUR[i][0] == d) return AC_DUR[i][1]; return d; }
function ac_renderAlerts(){
	var h = '', body, f, g, i;
	body = ac_rowh('Show alerts on the logo', ac_switch(AC.alerts == '1', "AC.alerts=(AC.alerts=='1'?'0':'1');ac_render();", 'Show alerts on the logo'),
		'Off: the logo only shows the scene, and Aura-CTRL stops checking for alerts.');
	body += ac_rowh('Several alerts at once', ac_switch(AC.multi, "ac_opt('multi')", 'Several alerts at once'),
		'The most severe alert is shown with its animation; the colours of the other active alerts appear briefly every 10 seconds. With a known zone map, up to 3 alerts (none Critical) share the logo. Off: only the most severe alert.');
	h += ac_table('Alerts on the logo', body);
	// family colours
	var fams = '<div class="ac-fams">';
	for (f = 0; f < 8; f++) {
		fams += '<div class="ac-fam"><input type="color" class="ac-swatch" value="#' + AC.fam[f] + '" onchange="AC.fam[' + f + ']=this.value.replace(\'#\',\'\').toLowerCase();ac_render();" aria-label="' + ac_esc(f < 6 ? AC_FAM_NAMES[f] : AC.cname[f - 6]) + ' colour">' +
			(f < 6 ? '<span>' + ac_esc(AC_FAM_NAMES[f]) + '</span>' : '<input type="text" maxlength="20" value="' + ac_esc(AC.cname[f - 6]) + '" onchange="AC.cname[' + (f - 6) + ']=ac_clean(this.value)||\'Custom ' + (f - 5) + '\';" aria-label="Name of custom colour ' + (f - 5) + '">') +
			'<span class="ac-mono ac-muted">#' + AC.fam[f] + '</span></div>';
	}
	fams += '</div><span class="ac-help" style="max-width:none;">Every alert uses the colour of its family, unless you give it Custom 1, Custom 2 or its own colour. You can rename the two custom colours.</span>';
	h += ac_table('Family colours', '<tr><td colspan="2">' + fams + '</td></tr>', '<button type="button" class="ac-btn" onclick="ac_resetColours()">Reset colours</button>');
	// alert list
	var st = window.auractrl_status, act = st && st.active ? ',' + st.active + ',' : '', en = 0, list = '<div class="ac-list">';
	for (var k in AC.al) if (AC.al[k].on) en++;
	for (g = 0; g < 6; g++) {
		var rows = '', cnt = 0, on = 0, live = 0;
		for (i = 0; i < AC_ALERTS.length; i++) {
			var d = AC_ALERTS[i]; if (d[2] != g) continue;
			var id = d[0], a = AC.al[id], isAct = act.indexOf(',' + id + ',') >= 0; cnt++; if (a.on) on++; if (isAct) live++;
			rows += '<div class="ac-arow' + (a.on ? '' : ' off') + '">' + ac_switch(a.on, "AC.al['" + id + "'].on=!AC.al['" + id + "'].on;ac_render();", d[1]) +
				'<div style="min-width:0;"><div class="ac-aname">' + ac_esc(d[1]) + ' <span class="ac-badge ac-sev-' + d[3] + '">' + AC_SEV[d[3]] + '</span>' + (isAct ? '<span class="ac-live">&#9679; active now</span>' : '') + '</div>' +
				'<div class="ac-asum">' + ac_signalText(id) + '</div></div>' +
				ac_preview({anim: a.look.anim, n: a.look.n, c: [ac_srcColour('a_' + id), a.look.c[1], a.look.c[2]], speed: a.look.speed, dir: a.look.dir}, 'mini') +
				'<div class="ac-btnrow"><button type="button" class="ac-btn" onclick="ac_test(\'' + id + '\')">Test</button>' +
				'<button type="button" class="ac-btn' + (ac_editing[id] ? ' sel' : '') + '" onclick="ac_editing[\'' + id + '\']=!ac_editing[\'' + id + '\'];ac_render();" aria-expanded="' + !!ac_editing[id] + '">' + (ac_editing[id] ? 'Close' : 'Edit') + '</button></div></div>';
			if (ac_editing[id]) rows += '<div class="ac-aedit">' + ac_alertEditor(id) + '</div>';
		}
		list += '<button type="button" class="ac-fhead" onclick="ac_openFam[' + g + ']=!ac_openFam[' + g + '];ac_render();" aria-expanded="' + !!ac_openFam[g] + '">' +
			(ac_openFam[g] ? '&#9662;' : '&#9656;') + ' <span class="ac-dot" style="background:#' + AC.fam[g] + '"></span>' + ac_esc(AC_FAM_NAMES[g]) +
			(live ? ' <span class="ac-live">&#9679; ' + live + ' active</span>' : '') + '<span class="ac-count">' + on + ' of ' + cnt + ' on</span></button>';
		if (ac_openFam[g]) list += rows;
	}
	list += '</div>';
	h += ac_table('Alert list', '<tr><td colspan="2" style="padding:0;"><span class="ac-help" style="padding:8px 10px;margin:0;max-width:none;">Critical alerts are shown first, then Warning, then Info. Test shows an alert on the logo for 10 seconds; Edit changes how it is shown.</span>' + list + '</td></tr>', en + ' of ' + AC_ALERTS.length + ' on');
	ac_el('pane_alerts').innerHTML = h;
}
function ac_alertEditor(id){
	var a = AC.al[id], d = ac_alertDef(id), i;
	var h = '<div class="ac-desc">' + ac_esc(d[5]) + '</div><div class="ac-aopts"><label class="ac-fld">Colour<select class="input_option" onchange="AC.al[\'' + id + '\'].src=this.value;ac_render();">';
	var srcs = [['fam', 'Family colour (' + AC_FAM_NAMES[d[2]] + ')'], ['c1', AC.cname[0]], ['c2', AC.cname[1]], ['own', 'Own colour']];
	for (i = 0; i < srcs.length; i++) h += '<option value="' + srcs[i][0] + '"' + (a.src == srcs[i][0] ? ' selected' : '') + '>' + ac_esc(srcs[i][1]) + '</option>';
	h += '</select></label><label class="ac-fld">Duration<select class="input_option" onchange="AC.al[\'' + id + '\'].dur=this.value;ac_render();">';
	for (i = 0; i < AC_DUR.length; i++) h += '<option value="' + AC_DUR[i][0] + '"' + (a.dur == AC_DUR[i][0] ? ' selected' : '') + '>' + AC_DUR[i][1] + '</option>';
	h += '</select></label><div class="ac-fld">At night' + (AC.dn ? '<label class="ac-row" style="font-size:12px;color:#d3dcdf;"><input type="checkbox"' + (a.night ? ' checked' : '') + ' onclick="AC.al[\'' + id + '\'].night=this.checked;ac_render();"> Show at night</label>' : '<span class="ac-muted" style="font-size:11px;">Turn on day and night scenes in Lighting</span>') + '</div></div>';
	return h + ac_editor('a_' + id, false);
}

function ac_renderDiag(){
	var s = window.auractrl_status || {}, h = '', body, i;
	var verified = !!s.model_zones, zones = s.zones ? s.zones.split(' ').length : 0, busy = !!(s.identify || s.calib);
	// router
	body = ac_rowh('Model', '<b>' + ac_esc(s.model || '-') + '</b> &middot; ' + (verified ? '<span class="ac-ok">zone map verified (' + zones + ' zones)</span>' : (zones ? '<span class="ac-ok">' + zones + ' zones, chosen by you</span>' : '<span class="ac-warn">light zones not set</span>')),
		zones ? 'All features are available.' : 'Router effects, Colour steps and Traffic meter work. Animations made by the add-on are shown as the closest router effect, transitions are instant and several alerts are shown one after the other. Test the light zones below and choose 3 or 5 zones to use all features.');
	body += ac_rowh('Aura RGB support', (s.supported == '1' ? '<span class="ac-ok">yes</span>' : '<span class="ac-bad">no (aura_rgb missing in rc_support)</span>') + (s.leds_off == '1' ? ' &middot; <span class="ac-warn">router LEDs are off: Aura-CTRL waits</span>' : ''));
	body += ac_rowh('CPU temperature', s.temp ? (parseInt(s.temp, 10) / 1000).toFixed(1) + ' &deg;C' : '-');
	h += ac_table('Router', body);
	// light zones
	body = '';
	if (s.bus != '1') body += ac_rowh('Test a zone', '<span class="ac-bad">No light controller bus (I2C) found on this router.</span>');
	else {
		var zb = '<div class="ac-btnrow">';
		for (var z = 1; z <= 5; z++) zb += '<button type="button" class="ac-btn' + (s.identify == String(z) ? ' sel' : '') + '" onclick="ac_identify(' + z + ')"' + (busy ? ' disabled' : '') + '>Zone ' + z + '</button>';
		zb += '<label class="ac-row" style="margin-left:8px;">for <select id="ac_identsec" class="input_option" onchange="ac_identSec=parseInt(this.value,10)||5;">';
		for (i = 3; i <= 10; i++) zb += '<option value="' + i + '"' + (i == ac_identSec ? ' selected' : '') + '>' + i + ' s</option>';
		zb += '</select></label></div>';
		body += ac_rowh('Test a zone', zb, 'The zone lights up in white and the others turn off. Note which part of the logo lights up, or "nothing". At the end the logo goes back to normal.' +
			(verified ? '' : ' Your model is not verified yet: please report your results on GitHub or SNBForums.'));
	}
	if (verified) body += ac_rowh('Zones used', zones + ' (zones 1&ndash;' + zones + ', verified for this model)');
	else {
		var opts = [['none', 'Not set: router effects only'], ['3', '3 zones (1 to 3, left to right)'], ['5', '5 zones (1 to 5, left to right)']], sel = '<select id="ac_zones" class="input_option" onchange="AC.zones=this.value;">';
		for (i = 0; i < opts.length; i++) sel += '<option value="' + opts[i][0] + '"' + (AC.zones == opts[i][0] ? ' selected' : '') + '>' + opts[i][1] + '</option>';
		body += ac_rowh('Zones used', sel + '</select>', 'Choose 3 zones if only zones 1, 2 and 3 light up, 5 zones if all of them do, then Save. If the logo looks wrong, go back to Not set.');
	}
	h += ac_table('Light zones', body);
	// colour correction
	var c = ac_corrNow(), m = s.corr_model || '100,100,100', names = ['Red', 'Green', 'Blue'];
	body = '<tr><td colspan="2"><span class="ac-help" style="margin:0;max-width:none;">The LEDs of the logo do not show colours like a screen: often green and blue are stronger, so yellow looks green and white looks blue. Lower a colour until the test colours look right on the logo. The page shows colours as you choose them; the correction applies only on the logo.</span></td></tr>';
	for (i = 0; i < 3; i++)
		body += ac_rowh(names[i], '<input type="range" min="20" max="100" step="1" value="' + c[i] + '" style="width:220px;vertical-align:middle;" aria-label="' + names[i] + ' correction" oninput="ac_el(\'ac_corrv' + i + '\').innerHTML=this.value+\'%\';" onchange="ac_setCorr(' + i + ',this.value)"> <b id="ac_corrv' + i + '">' + c[i] + '%</b>');
	var cb = '<div class="ac-btnrow">';
	for (i = 0; i < AC_CAL.length; i++) cb += '<button type="button" class="ac-btn" onclick="ac_calib(\'' + AC_CAL[i][0] + '\')"' + (busy ? ' disabled' : '') + '><span class="ac-dot" style="background:#' + AC_CAL[i][0] + '"></span>' + AC_CAL[i][1] + '</button>';
	cb += '<button type="button" class="ac-btn" onclick="ac_calibFam()"' + (busy ? ' disabled' : '') + '>All family colours</button></div>';
	body += ac_rowh('Show on the logo', cb, 'With the values above, even before you save them: 5 seconds per colour, 4 seconds per family colour.');
	body += ac_rowh('Default for this model', m.split(',').join(' / ') + ' %' + (m == '100,100,100' ? ' <span class="ac-muted">(no correction measured)</span>' : '') +
		' <button type="button" class="ac-btn" style="margin-left:8px;" onclick="AC.corr=null;ac_render();"' + (AC.corr ? '' : ' disabled') + '>Use the default</button>', AC.corr ? 'You are using your own values: Save to keep them.' : 'In use.');
	h += ac_table('Colour correction', body);
	if (s.newdev) {
		var nd = s.newdev.split(';'), l = '';
		for (i = 0; i < nd.length; i++) if (nd[i]) l += ac_esc(nd[i]) + '<br>';
		h += ac_table('Unknown devices', '<tr><td colspan="2" class="ac-mono">' + l + '<span class="ac-help">Acknowledge adds them to the known devices.</span></td></tr>');
	}
	if (s.eviltwin) h += ac_table('Access points using your network name', '<tr><td colspan="2" class="ac-mono">' + ac_esc(s.eviltwin) + '</td></tr>');
	h += ac_table('Recent events', '<tr><td colspan="2"><div class="ac-log">' + (s.events ? ac_esc(s.events).split('|').join('\n') : '-') + '</div></td></tr>');
	ac_el('pane_diagnostics').innerHTML = h;
}
function ac_setCorr(i, v){ var c = ac_corrNow().slice(); c[i] = ac_pct(v); AC.corr = c; ac_render(); }

function ac_renderFoot(){
	var tabName = ac_tab.charAt(0).toUpperCase() + ac_tab.substring(1), h = '<div class="ac-btnrow" style="justify-content:center;">' +
		'<button type="button" class="ac-btn primary" style="min-width:110px;" onclick="ac_save()">Save</button>' +
		'<button type="button" class="ac-btn" onclick="ac_restoreAsk=!ac_restoreAsk;ac_renderFoot();" aria-expanded="' + ac_restoreAsk + '">Restore defaults&hellip;</button></div>';
	if (ac_restoreAsk) h += '<div class="ac-confirm" role="group" aria-label="Restore defaults">Restore the defaults of' +
		'<button type="button" class="ac-btn" onclick="ac_restore(false)">' + tabName + ' only</button>' +
		'<button type="button" class="ac-btn" onclick="ac_restore(true)">Everything</button>' +
		'<button type="button" class="ac-btn" onclick="ac_restoreAsk=false;ac_renderFoot();">Cancel</button></div>';
	h += '<span class="ac-credit">Aura-CTRL by iggenio &middot; developed with the assistance of Claude (Anthropic) &middot; GPL-3.0-or-later</span>';
	ac_el('ac_foot').innerHTML = h;
}

/* ------------------------------------------------------------ status from the router */
function ac_renderStatus(){
	var s = window.auractrl_status;
	if (!s) { ac_el('ac_now').innerHTML = '<div class="ac-now-title">Status not available yet</div><div class="ac-now-detail">The router writes it within a minute of the installation.</div>'; return; }
	if (s.version) ac_el('ac_version').innerHTML = 'v' + ac_esc(s.version);
	var p = String(s.plan || '').split(' '), title = '-', detail = '', prev = '', i;
	if (p[0] == 'auraoff') { title = 'Aura RGB is off'; prev = ac_preview({anim:'off', n:0, c:['000000']}); }
	else if (p[0] == 'show') {
		var l = ac_parseLook(p[1]), what = p[2] || '', a = ac_anim(l.anim);
		prev = ac_preview(l);
		if (what.indexOf('scene:') == 0) {
			title = what == 'scene:night' ? 'Night scene' : (AC.dn ? 'Day scene' : 'Scene');
			detail = ac_esc(a.name) + (a.id == 'traffic' ? (s.traffic !== '' ? ' &middot; traffic ' + ac_esc(s.traffic) + '%' : ' &middot; enter the line speed in Lighting') : '');
		} else {
			var id = what.split(':')[1], d = ac_alertDef(id);
			title = (what.indexOf('test:') == 0 ? 'Test: ' : '') + (d ? ac_esc(d[1]) : ac_esc(id));
			detail = (d ? AC_SEV[d[3]] + ' &middot; ' : '') + ac_esc(a.name);
			if (p[3] && p[3].indexOf('remind:') == 0) detail += ' &middot; the other active alerts appear every 10 s';
		}
	} else if (p[0] == 'share') {
		var cols = (p[1] || '').split(','), ids = (p[3] || '').replace('alerts:', '').split(','), names = [];
		for (i = 0; i < ids.length; i++) { var dd = ac_alertDef(ids[i]); if (dd) names.push(dd[1]); }
		title = names.length + ' alerts share the logo'; detail = ac_esc(names.join(', '));
		prev = ac_preview({anim:'multi', n:cols.length, c:[cols[cols.length - 1], cols[1] || cols[0], cols[0]]});
	}
	if (s.identify) { title = 'Light zone test'; detail = 'Zone ' + ac_esc(s.identify) + ' is lit in white, the others are off.'; prev = ''; }
	else if (s.calib) { title = 'Colour test'; detail = s.calib == 'families' ? 'Family colours' : (s.calib.indexOf('effect') == 0 ? 'Router effect test from SSH' : '#' + ac_esc(s.calib)); }
	// active alerts as chips, with details
	var act = s.active ? s.active.split(',') : [], chips = '', det = '';
	for (i = 0; i < act.length; i++) { var x = ac_alertDef(act[i]); if (x) chips += '<span class="ac-chip"><span class="ac-dot" style="background:#' + AC.fam[x[2]] + '"></span>' + ac_esc(x[1]) + '</span>'; }
	if (act.join(',').indexOf('newdev') >= 0 && s.newdev) {
		var nd = s.newdev.split(';');
		for (i = 0; i < nd.length; i++) if (nd[i]) { var f = nd[i].split(' '); det += '<span class="ac-detail">Unknown device: <b>' + ac_esc(f[0]) + '</b>' + (f[1] && f[1] != '*' ? ' (' + ac_esc(f[1]) + ')' : '') + '</span>'; }
	}
	if (act.join(',').indexOf('eviltwin') >= 0 && s.eviltwin) det += '<span class="ac-detail">Access point using your network name: <b>' + ac_esc(s.eviltwin) + '</b></span>';
	ac_el('ac_logo').innerHTML = prev;
	ac_el('ac_now').innerHTML = '<div class="ac-now-label">Now on the logo</div><div class="ac-now-title">' + title + '</div><div class="ac-now-detail">' + detail + '</div>' +
		(chips ? '<div class="ac-chips">' + chips + '</div>' + det : '') + '<span class="ac-updated">Updated ' + ac_esc(s.time) + '</span>';
	ac_el('ac_ackbox').innerHTML = act.length ? '<button type="button" class="ac-btn" onclick="ac_ack()" title="Clears the alerts shown now and accepts unknown devices and configuration changes">Acknowledge</button>' : '';
	// the diagnostics follow the status, unless the user is using a control there
	var pd = ac_el('pane_diagnostics'), ae = document.activeElement;
	if (!(ae && pd.contains(ae) && (ae.tagName == 'SELECT' || ae.type == 'range'))) ac_renderDiag();
}
function ac_loadStatus(){
	var old = ac_el('ac_status_js'); if (old) old.parentNode.removeChild(old);
	var sc = document.createElement('script');
	sc.id = 'ac_status_js';
	sc.src = '/user/auractrl_status.js?t=' + new Date().getTime();
	sc.onload = ac_renderStatus;
	sc.onerror = ac_renderStatus;
	document.getElementsByTagName('head')[0].appendChild(sc);
}

/* ------------------------------------------------------------ messages: one notice for the whole page */
var ac_toastTimer = null;
// kind: 'ok' (green, closes by itself), 'info' (stays until replaced), 'err' (red, stays until closed)
function ac_msg(t, kind){
	var e = ac_el('ac_toast');
	if (!e) return;
	if (ac_toastTimer) { clearTimeout(ac_toastTimer); ac_toastTimer = null; }
	if (!t) { e.className = 'ac-toast'; return; }
	ac_el('ac_toast_text').innerHTML = t;
	e.className = 'ac-toast show' + (kind ? ' ' + kind : '');
	if (kind == 'ok') ac_toastTimer = setTimeout(function(){ ac_msg(''); }, 5000);
}

/* ------------------------------------------------------------ actions */
// settings = object to store (null = keep the saved ones), script = rc action, done = message when it worked.
// Sent in the background (no progress page, no reload); the classic form submit only without jQuery.
function ac_send(settings, script, done){
	var cs = JSON.parse(JSON.stringify(custom_settings));
	if (settings) { for (var k in settings) cs[k] = settings[k]; }
	if (typeof window.jQuery == 'undefined') {
		ac_el('amng_custom').value = JSON.stringify(cs);
		document.form.action_script.value = script;
		showLoading(3);
		document.form.submit();
		if (settings) { for (var k2 in settings) custom_settings[k2] = settings[k2]; }
		setTimeout(ac_loadStatus, 4000);
		return;
	}
	ac_msg(settings ? 'Saving&hellip;' : 'Sending to the router&hellip;', 'info');
	jQuery.ajax({url: '/start_apply.htm', type: 'POST', timeout: 15000,
		data: {action_mode: 'apply', action_script: script, action_wait: '0', modified: '0', current_page: ac_thisPage, next_page: ac_thisPage, amng_custom: JSON.stringify(cs)},
		success: function(){
			if (settings) { for (var k3 in settings) custom_settings[k3] = settings[k3]; }
			ac_msg(done || (settings ? 'Settings saved.' : 'Done.'), 'ok');
			setTimeout(ac_loadStatus, 1500); setTimeout(ac_loadStatus, 4000);
		},
		error: function(){ ac_msg((settings ? 'Nothing was saved: ' : '') + 'the router did not answer. Try again.', 'err'); }});
}
function ac_action(script, done){ ac_send(null, script, done); }
function ac_save(){
	var sc = [AC.day, AC.dn ? AC.night : null], warn = '';
	for (var i = 0; i < sc.length; i++) if (sc[i] && sc[i].anim == 'traffic' && !ac_trafficSet()) warn = ' Traffic meter needs the speed of your line: it stays at rest until you enter it.';
	ac_send(ac_settings(), 'start_auractrl', 'Settings saved.' + warn);
}
function ac_auraToggle(){
	AC.aura = (AC.aura == '1') ? '0' : '1';
	ac_render();
	ac_send({auractrl_aura: AC.aura}, 'start_auractrl', 'Aura RGB turned ' + (AC.aura == '1' ? 'on.' : 'off.'));
}
function ac_ack(){ ac_action('start_auractrlack', 'Alerts acknowledged.'); }
function ac_test(id){
	if (ac_dirty()) {
		if (!confirm('Settings have unsaved changes. Save them and test the alert?')) return;
		ac_send(ac_settings(), 'start_auractrltest' + id, 'Settings saved. Testing the alert on the logo for 10 seconds.');
	} else ac_action('start_auractrltest' + id, 'Testing the alert on the logo for 10 seconds.');
}
function ac_identify(z){
	ac_identSec = parseInt(ac_el('ac_identsec').value, 10) || 5;
	ac_action('start_auractrlident' + z + ac_identSec, 'Zone ' + z + ' lights up in white for ' + ac_identSec + ' seconds.');
}
function ac_calib(hex){ var c = ac_corrNow(); ac_action('start_auractrlcal' + hex + ac_pad3(c[0]) + ac_pad3(c[1]) + ac_pad3(c[2]), 'Showing #' + hex + ' on the logo for 5 seconds.'); }
function ac_calibFam(){ var c = ac_corrNow(); ac_action('start_auractrlfam' + ac_pad3(c[0]) + ac_pad3(c[1]) + ac_pad3(c[2]), 'Showing the saved family colours, 4 seconds each.'); }
function ac_resetColours(){
	AC.fam = AC_FAM_DEF.split(','); AC.cname = ['Custom 1', 'Custom 2'];
	ac_render();
	ac_msg('Family colours reset to defaults. Press Save to keep them.', 'info');
}
function ac_restore(all){
	var keep = JSON.parse(JSON.stringify(AC));
	for (var k in custom_settings) if (k.indexOf('auractrl_') == 0) delete custom_settings[k];
	var saved = JSON.parse(JSON.stringify(custom_settings));
	ac_load();
	if (!all) {
		var fresh = AC; AC = keep;
		if (ac_tab == 'lighting') { AC.dn = fresh.dn; AC.dayStart = fresh.dayStart; AC.nightStart = fresh.nightStart; AC.day = fresh.day; AC.night = fresh.night; AC.smooth = fresh.smooth; AC.eco = fresh.eco; AC.bright = fresh.bright; AC.traffic = fresh.traffic; AC.trate = fresh.trate; }
		if (ac_tab == 'diagnostics') { AC.zones = fresh.zones; AC.corr = fresh.corr; }
		if (ac_tab == 'alerts') { AC.alerts = fresh.alerts; AC.multi = fresh.multi; AC.fam = fresh.fam; AC.cname = fresh.cname; AC.al = fresh.al; }
	}
	custom_settings = saved;
	ac_restoreAsk = false;
	var s = ac_settings();   // custom_settings only stores keys that are sent: send them all
	ac_render();
	ac_send(s, 'start_auractrl', all ? 'All settings restored to defaults and saved.' : 'This tab restored to defaults and saved.');
}
function ac_selTab(t){ ac_tab = t; ac_restoreAsk = false; try { sessionStorage.setItem('auractrl_tab', t); } catch (e) {} ac_render(); }

function initial(){
	show_menu();
	document.form.current_page.value = ac_thisPage;
	document.form.next_page.value = ac_thisPage;
	try { var t = sessionStorage.getItem('auractrl_tab'); if (t == 'lighting' || t == 'alerts' || t == 'diagnostics') ac_tab = t; } catch (e) {}
	ac_load();
	ac_render();
	ac_loadStatus();
	setInterval(ac_loadStatus, 5000);
}
</script>
</head>
<body onload="initial();" class="bg">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" action="start_apply.htm" target="hidden_frame">
<input type="hidden" name="current_page" value="">
<input type="hidden" name="next_page" value="">
<input type="hidden" name="group_id" value="">
<input type="hidden" name="modified" value="0">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_wait" value="3">
<input type="hidden" name="first_time" value="">
<input type="hidden" name="action_script" value="">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
<input type="hidden" name="amng_custom" id="amng_custom" value="">
<table class="content" align="center" cellpadding="0" cellspacing="0">
<tr>
<td width="17">&nbsp;</td>
<td valign="top" width="202">
<div id="mainMenu"></div>
<div id="subMenu"></div>
</td>
<td valign="top">
<div id="tabMenu" class="submenuBlock"></div>
<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
<tr><td align="left" valign="top">
<table width="760px" border="0" cellpadding="5" cellspacing="0" class="FormTitle" id="FormTitle">
<tr><td bgcolor="#4D595D" valign="top">
<div id="ac_root">
<div>&nbsp;</div>
<div class="ac-top">
<div class="formfonttitle">Administration - Aura-CTRL<span id="ac_version" class="ac-ver"></span></div>
<div class="ac-master">Aura RGB <span id="ac_aura"></span></div>
</div>
<div style="margin:8px 0 8px 5px;" class="splitLine"></div>
<div class="ac-intro">Lighting sets how the Aura RGB logo looks when everything is fine. Alerts use the logo to show problems: the colour tells the family, the animation how urgent it is.</div>

<div class="ac-status" aria-live="polite">
<div id="ac_logo"></div>
<div id="ac_now" class="ac-now"></div>
<div id="ac_ackbox"></div>
</div>

<div id="ac_tabs" class="ac-tabs" role="tablist" aria-label="Aura-CTRL sections"></div>
<div id="pane_lighting" class="ac-pane"></div>
<div id="pane_alerts" class="ac-pane"></div>
<div id="pane_diagnostics" class="ac-pane"></div>

<div id="ac_foot" class="ac-foot"></div>
</div>
</td></tr>
</table>
</td></tr>
</table>
</td>
<td width="10" align="center" valign="top">&nbsp;</td>
</tr>
</table>
</form>
<div id="footer"></div>
<div id="ac_toast" class="ac-toast" role="status" aria-live="polite"><span id="ac_toast_text" class="ac-tt"></span><button type="button" onclick="ac_msg('')" aria-label="Close">&times;</button></div>
</body>
</html>
