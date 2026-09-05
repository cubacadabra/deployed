import{t as e}from"./clientConfig-CvB6XjxQ.js";var t=`/sudo-cadabra`,n={overview:{key:`overview`,path:t,index:`01`,navLabel:`Overview`,eyebrow:`Operations / capacity`,title:`Sudo-cadabra`,subtitle:`A live view of the tiny cloud behind the worlds.`},lobbies:{key:`lobbies`,path:`${t}/lobbies`,index:`02`,navLabel:`Lobbies`,eyebrow:`Monitor / lobby allocation`,title:`Lobbies`,subtitle:`See how players are distributed across the lobby instances.`},games:{key:`games`,path:`${t}/games-instances`,index:`03`,navLabel:`Game instances`,eyebrow:`Monitor / world allocation`,title:`Game instances`,subtitle:`Inspect the live capacity of each game world.`},players:{key:`players`,path:`${t}/player-clocks`,index:`04`,navLabel:`Player clocks`,eyebrow:`Monitor / eviction`,title:`Player clocks`,subtitle:`Track activity and idle timeouts for every connected player.`}};function r(){let e=window.location.pathname.replace(/\/+$/,``)||`/`;return Object.values(n).find(t=>t.path===e)??n.overview}function i(e){return new Intl.NumberFormat().format(e??0)}function a(e){return e?new Date(e).toLocaleString([],{month:`short`,day:`numeric`,hour:`2-digit`,minute:`2-digit`,second:`2-digit`}):`—`}function o(e){if(e==null)return`—`;if(e<=0)return`expired`;let t=Math.ceil(e/1e3),n=Math.floor(t/3600),r=Math.floor(t%3600/60),i=t%60;return n>0?`${n}h ${String(r).padStart(2,`0`)}m`:r>0?`${r}m ${String(i).padStart(2,`0`)}s`:`${i}s`}function s(e,t=``){let n=document.createElement(`td`);return t&&(n.className=t),n.textContent=e,n}function c(e){let t=s(e?o(e-Date.now()):`—`,`sudo-time-left`);return e&&(t.dataset.timeoutAt=String(e)),t}function l(e){let t=document.createElement(`span`);return t.className=`sudo-status sudo-status-${e}`,t.textContent=e,t}function u(e,t,n,r=``){let i=document.createElement(`article`);i.className=`sudo-metric ${r?`sudo-metric-${r}`:``}`;let a=document.createElement(`span`);a.className=`sudo-metric-label`,a.textContent=e;let o=document.createElement(`strong`);o.className=`sudo-metric-value`,o.textContent=t;let s=document.createElement(`span`);return s.className=`sudo-metric-detail`,s.textContent=n,i.append(a,o,s),i}function d(e){let t=document.createElement(`tr`);return e.forEach(e=>{t.append(e instanceof Node?e:s(e))}),t}function f(e){document.documentElement.classList.add(`sudo-document`),document.body.className=`sudo-page`,document.title=`${e.title} — cubacadabra`,document.body.innerHTML=`
    <div class="sudo-shell">
      <aside class="sudo-sidebar">
        <a class="sudo-brand" href="/" aria-label="Back to cubacadabra">
          <span class="sudo-brand-mark" aria-hidden="true"><span></span></span>
          <span>
            <strong>sudo-cadabra</strong>
            <small>capacity console</small>
          </span>
        </a>

        <div class="sudo-sidebar-rule"></div>
        <p class="sudo-nav-label">Monitor</p>
        <nav class="sudo-nav" aria-label="Admin sections">
          ${Object.values(n).map(t=>`
            <a class="${t.key===e.key?`is-active`:``}" href="${t.path}">
              <span class="sudo-nav-index">${t.index}</span>
              <span>${t.navLabel}</span>
            </a>
          `).join(``)}
        </nav>

        <div class="sudo-sidebar-footer">
          <span class="sudo-live-mark"></span>
          <span>Open access · v0.1</span>
        </div>
      </aside>

      <main class="sudo-main">
        <div class="sudo-main-content">
        <header class="sudo-header">
          <div>
            <p class="sudo-eyebrow">${e.eyebrow}</p>
            <h1>${e.title}</h1>
            <p class="sudo-subtitle">${e.subtitle}</p>
          </div>
          <div class="sudo-sync-state">
            <span class="sudo-sync-dot" id="sudo-sync-dot"></span>
            <span id="sudo-sync-copy">Connecting to telemetry</span>
          </div>
        </header>

        <div class="sudo-metrics" id="sudo-metrics" aria-live="polite"></div>

        <section class="sudo-panel" id="overview" data-panel="overview">
          <div class="sudo-panel-header">
            <div>
              <p class="sudo-eyebrow">Inventory</p>
              <h2>Instance ledger</h2>
            </div>
            <span class="sudo-panel-note" id="sudo-generated-at">Waiting for first read</span>
          </div>
          <div class="sudo-table-wrap">
            <table class="sudo-table" id="sudo-instance-table">
              <caption class="sudo-visually-hidden">All lobby and game instances</caption>
              <thead>
                <tr>
                  <th>Kind</th>
                  <th>World</th>
                  <th>Instance</th>
                  <th>Status</th>
                  <th>Players</th>
                  <th>Sockets</th>
                  <th>Reserved</th>
                  <th>Capacity</th>
                  <th>Created</th>
                  <th>Last used</th>
                  <th>Next timeout</th>
                </tr>
              </thead>
              <tbody></tbody>
            </table>
          </div>
          <div class="sudo-empty" id="sudo-instance-empty" hidden>No instance records yet.</div>
        </section>

        <section class="sudo-panel" id="lobbies" data-panel="lobbies">
          <div class="sudo-panel-header">
            <div>
              <p class="sudo-eyebrow">Lobby allocation</p>
              <h2>Lobby capacity</h2>
            </div>
            <span class="sudo-panel-note">Maximum three lobby instances</span>
          </div>
          <div class="sudo-table-wrap">
            <table class="sudo-table" id="sudo-lobby-table">
              <caption class="sudo-visually-hidden">Lobby instance details</caption>
              <thead>
                <tr>
                  <th>Lobby</th>
                  <th>Status</th>
                  <th>Players</th>
                  <th>Reservations</th>
                  <th>Instance age</th>
                  <th>Nearest timeout</th>
                  <th>Player clocks</th>
                </tr>
              </thead>
              <tbody></tbody>
            </table>
          </div>
        </section>

        <section class="sudo-panel" id="games" data-panel="games">
          <div class="sudo-panel-header">
            <div>
              <p class="sudo-eyebrow">World allocation</p>
              <h2>Game capacity</h2>
            </div>
            <span class="sudo-panel-note">Maximum three game instances</span>
          </div>
          <div class="sudo-table-wrap">
            <table class="sudo-table" id="sudo-game-table">
              <caption class="sudo-visually-hidden">Game instance details</caption>
              <thead>
                <tr>
                  <th>World</th>
                  <th>Instance</th>
                  <th>Status</th>
                  <th>Players</th>
                  <th>Reservations</th>
                  <th>Capacity</th>
                  <th>Nearest timeout</th>
                  <th>Player clocks</th>
                </tr>
              </thead>
              <tbody></tbody>
            </table>
          </div>
        </section>

        <section class="sudo-panel" id="players" data-panel="players">
          <div class="sudo-panel-header">
            <div>
              <p class="sudo-eyebrow">Eviction monitor</p>
              <h2>Player clocks</h2>
            </div>
            <span class="sudo-panel-note" id="sudo-timeout-note">Idle timeout: —</span>
          </div>
          <div class="sudo-table-wrap">
            <table class="sudo-table sudo-player-table" id="sudo-player-table">
              <caption class="sudo-visually-hidden">Player activity and idle timeout details</caption>
              <thead>
                <tr>
                  <th>Player</th>
                  <th>Kind</th>
                  <th>World</th>
                  <th>Instance</th>
                  <th>State</th>
                  <th>Sockets</th>
                  <th>Last activity</th>
                  <th>Timeout at</th>
                  <th>Time left</th>
                </tr>
              </thead>
              <tbody></tbody>
            </table>
          </div>
          <div class="sudo-empty" id="sudo-player-empty" hidden>No connected players.</div>
        </section>

        <div class="sudo-error" id="sudo-error" hidden></div>
        </div>
      </main>
    </div>
  `,document.querySelectorAll(`[data-panel]`).forEach(t=>{t.dataset.panel!==e.key&&t.remove()}),e.key!==`overview`&&document.querySelector(`#sudo-metrics`)?.remove()}function p(e){return[e.lobby,...e.games??[]].filter(Boolean)}function m(e){return p(e).flatMap(e=>(e.instances??[]).map(t=>({world:e,instance:t})))}function h(e){let t=p(e),n=e.lobby,r=e.games??[],a=n?.activeInstanceCount??0,s=r.reduce((e,t)=>e+(t.activeInstanceCount??0),0),c=n?.playerCount??0,l=r.reduce((e,t)=>e+(t.playerCount??0),0),d=t.reduce((e,t)=>e+(t.reservationCount??0),0),f=n?.maxInstances??3,m=r.reduce((e,t)=>e+(t.maxInstances??3),0),h=[u(`Active lobbies`,`${a} / ${f}`,`${i(c)} connected players`,`lobby`),u(`Game instances`,`${s} / ${m}`,`${i(l)} connected players`,`game`),u(`Pending reservations`,i(d),`handshakes in allocation`,`warm`),u(`Idle timeout`,o(e.idleTimeoutMs),`sweep every ${o(e.idleSweepIntervalMs)}`,`cool`)];document.querySelector(`#sudo-metrics`).replaceChildren(...h)}function g(e){let t=document.querySelector(`#sudo-instance-table tbody`),n=m(e).map(({world:e,instance:t})=>{let n=t.nearestTimeoutAt;return d([s(e.kind,`sudo-kind`),s(e.worldId,`sudo-mono`),s(t.instanceId,`sudo-mono`),l(t.status),s(i(t.playerCount)),s(i(t.connectionCount)),s(i(t.reservationCount)),s(`${t.playerCount} / ${e.maxPlayersPerInstance}`),s(a(t.createdAt),`sudo-muted`),s(a(t.lastUsedAt),`sudo-muted`),s(n?a(n):`—`,`sudo-mono`)])});t.replaceChildren(...n),document.querySelector(`#sudo-instance-empty`).hidden=n.length>0}function _(e,t,n){let r=document.querySelector(`${e} tbody`),a=m({lobby:n?t[0]:null,games:n?[]:t}).map(({world:e,instance:t})=>{let r=t.players??[],a=t.nearestTimeoutAt;return d(n?[s(t.instanceId,`sudo-mono`),l(t.status),s(`${t.playerCount} / ${e.maxPlayersPerInstance}`),s(i(t.reservationCount)),s(o(Date.now()-t.createdAt)),c(a),s(i(r.length))]:[s(e.worldId,`sudo-mono`),s(t.instanceId,`sudo-mono`),l(t.status),s(`${t.playerCount} / ${e.maxPlayersPerInstance}`),s(i(t.reservationCount)),s(`${t.playerCount} / ${e.maxPlayersPerInstance}`),c(a),s(i(r.length))])});r.replaceChildren(...a)}function v(e){let t=document.querySelector(`#sudo-player-table tbody`),n=m(e).flatMap(({world:e,instance:t})=>(t.players??[]).map(n=>{let r=n.idleTimeoutAt;return d([s(n.playerId,`sudo-mono`),s(e.kind,`sudo-kind`),s(e.worldId,`sudo-mono`),s(t.instanceId,`sudo-mono`),l(n.state),s(i(n.connectionCount??1)),s(a(n.lastActivityAt),`sudo-muted`),s(r?a(r):`—`,`sudo-mono`),c(r)])}));t.replaceChildren(...n),document.querySelector(`#sudo-player-empty`).hidden=n.length>0}function y(e){let t=document.querySelector(`#sudo-error`);t.textContent=e,t.hidden=!1,document.querySelector(`#sudo-sync-dot`).classList.add(`is-error`)}function b(){let e=document.querySelector(`#sudo-error`);e.hidden=!0,document.querySelector(`#sudo-sync-dot`).classList.remove(`is-error`)}function x(e,t=`live`){document.querySelector(`#sudo-sync-copy`).textContent=e,document.querySelector(`#sudo-sync-dot`).className=`sudo-sync-dot is-${t}`}async function S(t){x(`Reading instance telemetry`,`loading`);try{let n=await fetch(e(`/admin/status`),{cache:`no-store`,headers:{Accept:`application/json`}});if(!n.ok)throw Error(`Telemetry returned ${n.status}`);let r=await n.json();t.key===`overview`&&(h(r),g(r),document.querySelector(`#sudo-generated-at`).textContent=`Server read ${a(r.generatedAt)}`),t.key===`lobbies`&&_(`#sudo-lobby-table`,[r.lobby].filter(Boolean),!0),t.key===`games`&&_(`#sudo-game-table`,r.games??[],!1),t.key===`players`&&(v(r),document.querySelector(`#sudo-timeout-note`).textContent=`Idle timeout: ${o(r.idleTimeoutMs)}`),x(`Loaded · ${a(Date.now())}`,`live`),b()}catch(e){console.error(e),x(`Telemetry unavailable`,`error`),y(`Could not read sudo-cadabra telemetry. The backend may be offline.`)}}function C(){let e=r();f(e),S(e)}export{C as mountSudoCadabra};