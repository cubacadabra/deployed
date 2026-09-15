import"./modulepreload-polyfill-P2Xu9kJm.js";/* empty css               */import"./mobile-product-nav-CSCi2Eca.js";import{t as e}from"./clientConfig-CHb8n2eX.js";import{a as t,i as n,r,t as i}from"./session-DmmtMBw0.js";import{t as a}from"./stripeEmbeddedCheckout-B8b_znUF.js";import{n as o,t as s}from"./renderer-RJ3HlpJn.js";var c=67108864,l=1500,u=96,d=JSON.stringify({id:`web-morph-preview`,version:`0.0.0`,sdkVersion:`0.3.0`,package:{formatVersion:3,entry:`game.luau`},displayName:`Morph Preview`,lobby:!1,startWorld:`lobby`,launch:{destinationWorld:`lobby`,authoritative:!1},world:{groundSize:12,gridSize:0,gridDivisions:0,spawn:[0,0,0],showSpawnPad:!1}}),f=`return {}`;async function p(){let t=await fetch(e(`/morphs/catalog?limit=100`),{headers:{Accept:`application/json`}}),n=await t.json().catch(()=>null);if(!t.ok||!Array.isArray(n?.assets))throw Error(n?.error||`The morph catalog could not be loaded.`);return n.assets}async function m(e){let t=[];for(let[n,r]of Object.entries(e)){let e=await fetch(r.url);if(!e.ok)throw Error(`The morph pack "${n}" could not be loaded (${e.status}).`);let i=new Uint8Array(await e.arrayBuffer());if(i.length===0||i.length>c)throw Error(`The morph pack "${n}" exceeds the supported size limit.`);t.push(i)}return t}async function h({canvas:t}){let n=await p(),r=await s({canvas:t});try{let i=o(r.wasmExports,r.bindings,d,f);r.setAvatarPreviewMode(!0),i.setAuthenticated(!0);let a=!1,s=0,c=performance.now(),p=null,h=0,g=0,_=0,v=0,y=0,b=0,x=0,S=!0,C=null,w=new Set,T=Promise.resolve(),E=!1,D=[];function O(e,t,n,r){e.addEventListener(t,n,r),D.push(()=>e.removeEventListener(t,n,r))}function k(e){!C||e!==void 0&&C.id!==e||(C=null,_=0,v=0,t.classList.remove(`is-moving`,`is-looking`))}function A(e){if(C||e.pointerType===`mouse`&&e.button!==0&&e.button!==2)return;let n=t.getBoundingClientRect(),r=e.clientX-n.left,i=e.button===2||r>=n.width/2?`look`:`move`;e.preventDefault(),t.setPointerCapture(e.pointerId),t.focus({preventScroll:!0}),C={id:e.pointerId,mode:i,originX:e.clientX,originY:e.clientY,x:e.clientX,y:e.clientY},t.classList.add(i===`look`?`is-looking`:`is-moving`)}function j(e){C&&e.pointerId===C.id&&(e.preventDefault(),C.mode===`move`?(v=Math.max(-1,Math.min(1,(e.clientX-C.originX)/u)),_=Math.max(-1,Math.min(1,-(e.clientY-C.originY)/u))):(y+=e.clientX-C.x,b+=e.clientY-C.y),C.x=e.clientX,C.y=e.clientY)}function M(e){Math.abs(e.deltaY)<.5||(e.preventDefault(),x+=Math.sign(e.deltaY)*.9)}O(t,`pointerdown`,A),O(t,`pointermove`,j),O(t,`pointerup`,e=>k(e.pointerId)),O(t,`pointercancel`,e=>k(e.pointerId)),O(t,`lostpointercapture`,e=>k(e.pointerId)),O(t,`contextmenu`,e=>e.preventDefault()),O(t,`wheel`,M,{passive:!1});let N=typeof ResizeObserver>`u`?null:new ResizeObserver(()=>r.resize());N?N.observe(t):O(window,`resize`,r.resize);async function P(t){let i=[t.base,...t.parts||[]];t.face&&i.push(t.face);for(let t of i){let i=n.find(e=>e.id===t);if(!i)throw Error(`Morph asset "${t}" is missing from the catalog.`);if(w.has(i.id))continue;let a=i.artifact?.url;if(!a)throw Error(`Morph asset "${i.id}" has no schema-5 artifact.`);let o=await m({[i.id]:{url:new URL(a,e(`/`)).href}});if(!r.registerMorphPack(o[0]))throw Error(`The morph pack "${i.id}" was rejected by the renderer.`);w.add(i.id)}}function F(e){if(a)return;let t=Math.min((e-c)/1e3,.05);c=e;let n=e<h?p:null,o=_+ +(n===`walk`),l=v,u=Math.hypot(o,l);u>1&&(o/=u,l/=u),i.setInput(o,l,!1,n===`jump`,!1,y+(n===`turn`?6:0),b,x+(S?-6.5:0)),S=!1,y=0,b=0,x=0,i.step(t),r.render(i.rendererHandle()),s=requestAnimationFrame(F)}function I(e){if(!a&&e?.base)return T=T.catch(()=>{}).then(async()=>{if(await P(e),!a){if(g=Math.max(g,Number(e.revision)||0)+1,!i.setLocalMorphLoadout(JSON.stringify({...e,revision:g})))throw Error(`The morph preview rejected the selected v2 loadout.`);E||(E=!0,c=performance.now(),s=requestAnimationFrame(F))}}),T.catch(e=>console.error(`Morph preview update failed`,e)),T}function L(e){a||(p=e,h=performance.now()+l)}return{setMorphLoadout:I,play:L,destroy(){a||(a=!0,cancelAnimationFrame(s),k(),N?.disconnect(),D.forEach(e=>e()),r.destroy(),i.destroy())}}}catch(e){throw r.destroy(),e}}var g=`/login/?returnTo=${encodeURIComponent(`${window.location.pathname}${window.location.search}${window.location.hash}`)}`,_=document.querySelector(`.about-content`),v=[...document.querySelectorAll(`.about-menu > a`)],y=document.querySelector(`.about-sidebar-status`),b=`/subscription`,x=20,S=[`hair`,`face`,`headwear`,`facewear`,`top`,`bottom`,`footwear`,`accessory`],C=null,w,T,E=null;function D(e){if(!/^\d{4}-\d{2}-\d{2}$/.test(e||``))return null;let[t,n,r]=e.split(`-`).map(Number),i=new Date,a=i.getFullYear()-t;return i.getMonth()+1>n||i.getMonth()+1===n&&i.getDate()>=r||--a,a}function O(t){return typeof t!=`string`||!t.startsWith(`/morphs/`)?null:e(t).href}function k(e,t=e?`birthday`:`basics`){T?.(),T=null,document.body.classList.toggle(`is-morph-editor`,!e&&t===`morph-editor`);let n=v[0];n&&(n.href=e?`#birthday`:`#item1`,n.querySelector(`span`).textContent=e?`Birthday`:`Basics`,n.dataset.section=e?`birthday`:`basics`),v.slice(1).forEach(t=>{t.hidden=e}),v.forEach(e=>{let n=!e.hidden&&e.dataset.section===t;e.classList.toggle(`is-active`,n),n?e.setAttribute(`aria-current`,`page`):e.removeAttribute(`aria-current`)}),y&&(y.textContent=e?`Required to continue`:``)}function A(e,t,n=``){e.textContent=t,e.dataset.state=n}function j(e){return String(e).replaceAll(`&`,`&amp;`).replaceAll(`"`,`&quot;`).replaceAll(`'`,`&#39;`).replaceAll(`<`,`&lt;`).replaceAll(`>`,`&gt;`)}function M(e){return e.replaceAll(`-`,` `).replace(/\b\w/g,e=>e.toUpperCase())}function N(){return`
    <div class="birthday-view" id="birthday">
      <div class="birthday-intro">
        <p class="about-label">One important detail</p>
        <h1 id="birthday-title">Tell us when you were born.</h1>
        <p class="about-lede">Your birthday helps us create the right, safer experience for your age.</p>
      </div>

      <div class="birthday-workspace">
        <section class="birthday-guidance" aria-labelledby="birthday-guidance-title">
          <p class="birthday-kicker">A safer world for everyone</p>
          <h2 id="birthday-guidance-title">Real age, real protections.</h2>
          <p>cubacadabra takes COPPA and child safety seriously, so we need your real age to apply the right safeguards.</p>
          <p>If you’re a kid, please don’t lie about your age. If you follow the rules, tell us your real birthday, and have a parent sign up too, you can have a fun, safe experience and your parent will know which cubes you’re using.</p>
        </section>

        <form class="birthday-form" novalidate>
          <div class="birthday-form-heading">
            <p class="birthday-kicker">Your birthday</p>
            <p>Use the date on your official records. No time or location is needed.</p>
          </div>
          <div class="birthday-fields" role="group" aria-labelledby="birthday-fields-label">
            <span class="sr-only" id="birthday-fields-label">Birthday date</span>
            <label class="birthday-field birthday-field-year">
              <span>Year</span>
              <input name="year" type="text" inputmode="numeric" autocomplete="bday-year" maxlength="4" pattern="[0-9]{4}" placeholder="YYYY" autofocus required />
            </label>
            <label class="birthday-field">
              <span>Month</span>
              <input name="month" type="text" inputmode="numeric" autocomplete="bday-month" maxlength="2" pattern="[0-9]{1,2}" placeholder="MM" required />
            </label>
            <label class="birthday-field">
              <span>Day</span>
              <input name="day" type="text" inputmode="numeric" autocomplete="bday-day" maxlength="2" pattern="[0-9]{1,2}" placeholder="DD" required />
            </label>
          </div>
          <p class="birthday-form-note">Please enter a complete, valid calendar date.</p>
          <p class="birthday-status" role="alert" aria-live="polite"></p>
          <button class="birthday-submit" type="submit">Save birthday</button>
        </form>
      </div>
    </div>`}function P(){return`
    <div class="birthday-view birthday-view-parent" id="birthday">
      <div class="birthday-intro">
        <p class="about-label">A parent or guardian is next</p>
        <h1 id="parent-title">Let’s bring a parent in.</h1>
        <p class="about-lede">Thanks for sharing your real birthday. Because you’re under 13, we need a parent’s email before you can continue.</p>
      </div>

      <div class="birthday-workspace birthday-workspace-parent">
        <section class="birthday-guidance" aria-labelledby="parent-guidance-title">
          <p class="birthday-kicker">Why we ask</p>
          <h2 id="parent-guidance-title">Safety works better together.</h2>
          <p>Ask your parent or guardian to sign up with you. They’ll be able to know which cubes you’re using while you enjoy a fun, safe experience.</p>
          <p class="birthday-parent-note">Please ask a parent or guardian for permission before entering their email.</p>
        </section>

        <form class="birthday-form parent-email-form" novalidate>
          <div class="birthday-form-heading">
            <p class="birthday-kicker">Parent or guardian email</p>
            <p>We’ll use this to start the parent sign-up step.</p>
          </div>
          <label class="parent-email-field">
            <span>Email address</span>
            <input id="parent-email" name="parent-email" type="email" autocomplete="email" placeholder="parent@example.com" required autofocus />
          </label>
          <p class="birthday-status" role="status" aria-live="polite"></p>
          <button class="birthday-submit" type="submit">Continue with a parent</button>
        </form>
      </div>
    </div>`}function F(){return`
    <div class="basics-view" id="item1">
      <div class="basics-workspace">
        <form class="basics-form" novalidate autocomplete="off">
          <div class="basics-heading">
            <h1>Basics</h1>
            <p>Update the name other players see.</p>
          </div>
          <label class="basics-field" for="my-cube-username">
            <span>Username</span>
            <input id="my-cube-username" name="username" type="text" autocomplete="nickname" aria-describedby="my-cube-username-help basics-username-status" spellcheck="false" required />
          </label>
          <p class="basics-field-help" id="my-cube-username-help">Use 2–24 letters, numbers, _ or -.</p>
          <p class="basics-status" id="basics-username-status" role="status" aria-live="polite"></p>
          <button class="basics-submit" type="submit" disabled>Save username</button>
        </form>
      </div>
    </div>`}function I(){return`
    <form class="morph-editor" id="morph-editor" novalidate>
      <div class="morph-editor-layout">
        <div class="morph-main-column">
          <div class="morph-editor-heading">
            <div><h1 id="morph-editor-title">Morph Editor</h1><p>Pick a starter, then make it yours.</p></div>
            <span class="morph-release" aria-live="polite"></span>
          </div>
          <section class="morph-preview" aria-labelledby="morph-editor-title">
            <div class="morph-preview-stage">
              <canvas class="morph-preview-canvas" tabindex="0" aria-label="Live 3D morph preview. Drag the left side to move and the right side to orbit the camera."></canvas>
              <div class="morph-preview-card">
                <h2 data-preview-name>Loading morph…</h2>
                <span class="morph-preview-kind">Starter morph</span>
                <p>A ready-to-play look you can customize.</p>
                <span class="morph-ready"><i></i>Ready to play</span>
              </div>
              <div class="morph-preview-overlay">
                <span>Left side moves · Right side orbits · Scroll zooms</span>
              </div>
            </div>
            <div class="morph-preview-controls" role="group" aria-label="Preview actions">
              <button type="button" data-preview-action="walk">Walk</button>
              <button type="button" data-preview-action="jump">Jump</button>
              <button type="button" data-preview-action="turn">Turn</button>
            </div>
          </section>
          <section class="morph-starters" aria-label="Starter morphs">
            <div class="morph-section-heading"><h2>Starter gallery</h2><span>Choose a ready-to-play look</span></div>
            <div class="morph-starter-grid"></div>
          </section>
        </div>
        <aside class="morph-inspector" aria-label="Morph controls">
          <div class="morph-tabs" role="tablist" aria-label="Morph editor">
            <button type="button" role="tab" aria-selected="false" data-morph-tab="starters">Starters</button>
            <button type="button" role="tab" aria-selected="true" data-morph-tab="customize">Customize</button>
          </div>
          <div class="morph-inspector-heading">
            <h2>Appearance</h2>
            <p>Combine clothing, hair, and accessories.</p>
          </div>
          <div class="morph-panel morph-starter-inspector" data-morph-panel="starters" role="tabpanel" hidden>
            <p>Choose a starter from the gallery below the preview. You can switch to Customize without losing it.</p>
          </div>
          <div class="morph-panel morph-customize-panel" data-morph-panel="customize" role="tabpanel"></div>
          <p class="morph-status" role="status" aria-live="polite"></p>
          <button class="morph-save" type="submit" disabled>Save Morph</button>
        </aside>
      </div>
    </form>`}function L(){return`
    <div class="cubes-view" id="cubes">
      <table class="cube-table" aria-label="Available cubes">
        <tbody>
          <tr>
            <td colspan="2">
              <a class="cube-link" href="/?game=first-game">
                <div class="cube-thumbnail" aria-hidden="true"><span>Thumbnail</span></div>
                <span class="cube-name">first-game</span>
              </a>
            </td>
          </tr>
          <tr>
            <td colspan="2">
              <a class="cube-link" href="/?game=second-game">
                <div class="cube-thumbnail" aria-hidden="true"><span>Thumbnail</span></div>
                <span class="cube-name">second-game</span>
              </a>
            </td>
          </tr>
          <tr class="cube-more-row">
            <td colspan="2">
              <a class="cube-link cube-more-link" href="#more-cubes">
                <div class="cube-thumbnail" aria-hidden="true"><span>More</span></div>
                <div class="cube-copy">
                  <span class="cube-name">More</span>
                  <span class="cube-detail">Browse uploaded cubes</span>
                </div>
              </a>
            </td>
          </tr>
        </tbody>
      </table>
    </div>`}function R(){return`
    <div class="cubes-view more-cubes-view" id="more-cubes">
      <div class="more-cubes-heading">
        <a class="cubes-back-link" href="#cubes">← All cubes</a>
        <h1>More</h1>
        <p>Browse uploaded cubes.</p>
      </div>
      <p class="more-cubes-status" role="status" aria-live="polite">Loading cubes…</p>
      <button class="more-cubes-retry" type="button" hidden>Try again</button>
      <table class="cube-table more-cube-table" aria-label="Uploaded cubes">
        <tbody class="more-cube-table-body"></tbody>
      </table>
    </div>`}function z(){return`
    <div class="blocked-users-view" id="blocked-users">
      <div class="blocked-users-heading">
        <h1 id="blocked-users-title">Blocked Users</h1>
        <span class="blocked-users-count" aria-live="polite"></span>
      </div>
      <p class="blocked-users-status" role="status" aria-live="polite">Loading blocked users…</p>
      <button class="blocked-users-retry" type="button" hidden>Try again</button>
      <ul class="blocked-users-list"></ul>
    </div>`}function B(){return[`<div class="subscription-view" id="subscription">`,`  <div class="subscription-heading">`,`    <h1 id="subscription-title">Subscription</h1>`,`  </div>`,`  <div class="subscription-plan">`,`    <strong>parent-cadabra</strong>`,`    <span>$9.99 USD / month</span>`,`    <p>Parents fund the platform directly, so kids can play without casino coins. Please note cubacadabra is a work in progress and your subscription helps fund it. Cancel anytime but please understand you are not buying a finished product yet only helping to support a new one.</p>`,`  </div>`,`  <p class="subscription-status" role="status" aria-live="polite">Checking subscription…</p>`,`  <button class="subscription-cancel-link" type="button" hidden>Cancel subscription</button>`,`  <button class="subscription-start" type="button" hidden>Continue to payment</button>`,`  <form class="subscription-checkout-form" hidden>`,`    <div class="subscription-payment" aria-label="Payment details"></div>`,`    <p class="subscription-checkout-status" role="status" aria-live="polite"></p>`,`    <button class="subscription-submit" type="submit" disabled>Subscribe for $9.99/month</button>`,`  </form>`,`</div>`].join(``)}function V(e){let t=typeof e?.status==`string`?e.status.trim().toLowerCase():``;return t?t.replace(/_/g,` `):`Not active`}function H(e){return[`active`,`trialing`,`past_due`,`unpaid`,`paused`].includes(typeof e?.status==`string`?e.status.trim().toLowerCase():``)}async function U(){let t=await fetch(e(b),{credentials:`include`,headers:{Accept:`application/json`}}),n=await t.json().catch(()=>null);if(!t.ok)throw Error(n?.error||`subscription_load_failed`);return n}async function ee(){let t=await fetch(e(`/subscription/checkout-session`),{method:`POST`,credentials:`include`,headers:{Accept:`application/json`,"content-type":`application/json`},body:`{}`}),n=await t.json().catch(()=>null);if(!t.ok)throw Error(n?.error||`subscription_checkout_failed`);return n}async function W(t){let n=await fetch(e(`/subscription/checkout-session/complete`),{method:`POST`,credentials:`include`,headers:{Accept:`application/json`,"content-type":`application/json`},body:JSON.stringify({checkout_session_id:t})}),r=await n.json().catch(()=>null);if(!n.ok)throw Error(r?.error||`subscription_completion_failed`);return r}async function te(t){let n=await fetch(e(`/subscription/cancel`),{method:`POST`,credentials:`include`,headers:{Accept:`application/json`,"content-type":`application/json`},body:JSON.stringify({subscription_id:t})}),r=await n.json().catch(()=>null);if(!n.ok)throw Error(r?.error||`subscription_cancel_failed`);return r}function G(e){return e.message===`not_authenticated`?`Your session has expired. Please sign in again.`:e.message===`age_required`?`Complete your birthday before starting a subscription.`:e.message===`subscription_cancel_failed`?`We couldn’t cancel the subscription. Please try again.`:e.message===`subscription_not_active`?`The subscription could not be confirmed. Please try again.`:e.message.includes(`not configured`)?`Subscriptions are not configured yet. Please try again later.`:`We couldn’t load subscription details. Please try again.`}function K(e){let t=e.slice(-4).toUpperCase();return t?`Player ${t}`:`Blocked user`}async function ne(){let e=await t(C);await e.dispatch({type:`load_blocked_users`});let n=e.snapshot.safety;if(n.feedback?.kind===`error`)throw Error(n.feedback.code);return{runtime:e,userIds:n.blocked_user_ids}}async function re(){let e=await t(C),n=!1;for(let t=1;t<=200;t+=1){await e.dispatch({type:`load_catalog`,page:t,page_size:x});let r=e.snapshot.catalog;if(r.feedback?.kind===`error`)throw Error(r.feedback.code);if(!r.has_next_page){n=!0;break}}if(!n)throw Error(`catalog_pagination_limit`);return e.snapshot.catalog.entries.map(e=>({cubeId:e.cube_id,version:e.version,displayName:e.display_name,packagePath:e.package_path,assetBaseURL:e.asset_base_url}))}function ie(e){return new URL(`/cube/${encodeURIComponent(e)}`,window.location.origin).href}function ae(e){let t=document.createElement(`tr`),n=document.createElement(`td`);n.colSpan=2;let r=document.createElement(`a`);r.className=`cube-link`,r.href=ie(e.cubeId);let i=document.createElement(`div`);i.className=`cube-thumbnail`,i.setAttribute(`aria-hidden`,`true`);let a=document.createElement(`span`);a.textContent=`Cube`,i.append(a);let o=document.createElement(`div`);o.className=`cube-copy`;let s=document.createElement(`span`);s.className=`cube-name`,s.textContent=typeof e.displayName==`string`&&e.displayName.trim()?e.displayName.trim():e.cubeId;let c=document.createElement(`span`);return c.className=`cube-detail`,c.textContent=`${e.cubeId} · v${e.version??`?`}`,o.append(s,c),r.append(i,o),n.append(r),t.append(n),t}function oe(e){return e.message===`age_required`?`Complete your birthday before viewing blocked users.`:e.message===`not_authenticated`?`Your session has expired. Please sign in again.`:`We couldn’t load your blocked users. Please try again.`}function se(e,t,n,r){let i=_.querySelector(`.blocked-users-list`);if(i.replaceChildren(),r.textContent=`${t.length} ${t.length===1?`user`:`users`}`,t.length===0){let e=document.createElement(`li`);e.className=`blocked-users-empty`,e.textContent=`You haven’t blocked anyone.`,i.append(e);return}t.forEach(t=>{let a=document.createElement(`li`);a.className=`blocked-user-row`;let o=document.createElement(`div`);o.className=`blocked-user-identity`;let s=document.createElement(`div`);s.className=`blocked-user-details`;let c=document.createElement(`strong`);c.textContent=K(t);let l=document.createElement(`code`);l.textContent=t,s.append(c,l),o.append(s);let u=document.createElement(`button`);u.className=`blocked-user-unblock`,u.type=`button`,u.textContent=`Unblock`,u.setAttribute(`aria-label`,`Unblock ${K(t)}`),u.addEventListener(`click`,async()=>{u.disabled=!0,u.textContent=`Unblocking…`,n.textContent=`Saving your change…`,n.dataset.state=`pending`;try{await e.dispatch({type:`unblock_user`,user_id:t});let o=e.snapshot.safety;if(o.feedback?.kind===`error`)throw Error(o.feedback.code);a.remove();let s=i.querySelectorAll(`.blocked-user-row`).length;if(r.textContent=`${s} ${s===1?`user`:`users`}`,s===0){let e=document.createElement(`li`);e.className=`blocked-users-empty`,e.textContent=`You haven’t blocked anyone.`,i.append(e)}n.textContent=`${K(t)} was unblocked.`,n.dataset.state=`success`}catch{u.disabled=!1,u.textContent=`Unblock`,n.textContent=`We couldn’t unblock this user. Please try again.`,n.dataset.state=`error`}}),a.append(o,u),i.append(a)})}function ce(){k(!0),_.innerHTML=N();let e=_.querySelector(`.birthday-form`),n=_.querySelector(`.birthday-status`),r=e.querySelector(`.birthday-submit`);e.addEventListener(`submit`,async i=>{i.preventDefault();let a=e.elements.year.value.trim(),o=e.elements.month.value.trim(),s=e.elements.day.value.trim(),c=Number(o),l=Number(s);if(!/^\d{4}$/.test(a)||!/^\d{1,2}$/.test(o)||!/^\d{1,2}$/.test(s)||c<1||c>12||l<1||l>31){A(n,`Enter a complete, valid birthday.`,`error`);return}r.disabled=!0,A(n,`Saving your birthday…`);let u=`${a}-${String(c).padStart(2,`0`)}-${String(l).padStart(2,`0`)}`;try{let e=await t(C);await e.dispatch({type:`save_birthday`,date_of_birth:u});let n=e.snapshot;if(n.account_id!==C?.id||n.profile.date_of_birth!==u)throw Error(n.profile.birthday_feedback?.code||`birthday_save_failed`);C={...C,dob:n.profile.date_of_birth},D(n.profile.date_of_birth)<13?q():J(C)}catch(e){r.disabled=!1,A(n,e.message===`invalid_date_of_birth`?`That date is not valid. Check the year, month, and day, then try again.`:`We couldn’t save your birthday. Please try again.`,`error`)}})}function q(){k(!0),_.innerHTML=P();let e=_.querySelector(`.parent-email-form`),t=_.querySelector(`#parent-email`),n=_.querySelector(`.birthday-status`);e.addEventListener(`submit`,e=>{if(e.preventDefault(),!t.validity.valid){t.focus(),A(n,`Enter your parent or guardian’s email address.`,`error`);return}A(n,`Parent sign-up will continue here next.`)}),t.focus()}async function J(e){k(!1),_.innerHTML=F();let t=_.querySelector(`.basics-form`),n=_.querySelector(`#my-cube-username`),r=_.querySelector(`#basics-username-status`),i=t.querySelector(`.basics-submit`);n.disabled=!0,A(r,`Loading profile…`);let a;try{a=await w}catch{if(!t.isConnected)return;A(r,`We couldn’t load your profile. Please reload and try again.`,`error`),i.disabled=!1,i.textContent=`Reload`,t.addEventListener(`submit`,e=>{e.preventDefault(),window.location.reload()});return}if(!t.isConnected)return;a.dispatch({type:`begin_username_edit`});let o=a.snapshot.session_id,s=a.snapshot.account_id,c=()=>s!==null&&a.snapshot.session_id===o&&a.snapshot.account_id===s,l=!1,u=null,d=({profile:e})=>{if(!t.isConnected)return;let a=c();n.value!==e.username_draft&&(n.value=e.username_draft),n.disabled=!a,n.setAttribute(`aria-invalid`,String(e.username_feedback?.kind===`error`&&e.username_validation_error!==null)),i.disabled=!a||l||e.username_is_saving||!e.username_can_save,i.setAttribute(`aria-busy`,String(l||e.username_is_saving));let o=u??e.username_feedback;A(r,a?o?.kind===`error`?o.message:l||e.username_is_saving?`Saving username…`:o?.message??``:`Please sign in again.`,a?o?.kind===`error`?`error`:l||e.username_is_saving?`pending`:o?.kind??``:`error`)};T=a.subscribe(d),n.addEventListener(`input`,()=>{u=null,a.dispatch({type:`username_changed`,value:n.value})}),t.addEventListener(`submit`,async e=>{if(e.preventDefault(),!(!c()||l||a.snapshot.profile.username_is_saving)){l=!0,u=null,d(a.snapshot);try{await a.dispatch({type:`save_username`});let e=a.snapshot.profile;if(!c()||!t.isConnected||e.username_validation_error||e.username_is_dirty||e.username_feedback?.kind===`error`)return;C={...C,username:e.username},u={kind:`success`,message:`Username saved.`}}catch{u={kind:`error`,message:`We couldn’t save your username. Please try again.`}}finally{l=!1,d(a.snapshot)}}}),n.focus(),n.select()}async function Y(){k(!1,`morph-editor`),_.innerHTML=I();let e=_.querySelector(`.morph-editor`),t=e.querySelector(`.morph-starter-grid`),n=e.querySelector(`[data-morph-panel="customize"]`),r=e.querySelector(`.morph-status`),i=e.querySelector(`.morph-save`),a=document.querySelector(`.morph-topbar-search input`),o;try{o=await w}catch{if(!e.isConnected)return;A(r,`We couldn’t load the Morph Editor. Please reload and try again.`,`error`);return}if(!e.isConnected)return;await o.dispatch({type:`load_appearance_catalog`}),await o.dispatch({type:`begin_appearance_edit`});let s=o.snapshot.session_id,c=o.snapshot.account_id,l=()=>c!==null&&o.snapshot.session_id===s&&o.snapshot.account_id===c,u=!1,d=null,f=null,p=!1,m=`customize`,g=``,v=new Set([`base`,`hair`]),y=t=>{m=t,e.dataset.activeTab=t,e.querySelectorAll(`[data-morph-tab]`).forEach(e=>{e.setAttribute(`aria-selected`,String(e.dataset.morphTab===t))}),e.querySelectorAll(`[data-morph-panel]`).forEach(e=>{e.hidden=e.dataset.morphPanel!==t})},b=({appearance:a})=>{if(!e.isConnected)return;let s=l(),c=a.presets.find(e=>e.id===a.draft_preset_id),p=a.presets.filter(e=>e.display_name.toLowerCase().includes(g));e.querySelector(`.morph-release`).textContent=a.release?`Catalog ${a.release}`:``,t.innerHTML=a.is_loading?`<p class="morph-empty">Loading morphs…</p>`:p.map(e=>{let t=O(e.thumbnail);return`
          <button type="button" class="morph-choice ${c?.id===e.id?`is-selected`:``}" data-preset-id="${j(e.id)}" ${!s||a.is_saving?`disabled`:``}>
            <span class="morph-choice-figure" aria-hidden="true">
              ${t?`<img src="${j(t)}" alt="" loading="lazy" decoding="async">`:``}
            </span>
            <span>${j(e.display_name)}</span>
            <small>${e.parts.length?`Ready to play`:`Base morph`}</small>
          </button>`}).join(``)||`<p class="morph-empty">${g?`No starters match your search.`:`No starter morphs are available.`}</p>`;let h=a.assets.filter(e=>e.kind===`base`),_=new Map;a.assets.forEach(e=>{e.kind!==`base`&&_.set(e.kind,[..._.get(e.kind)||[],e])});let b=[...S.filter(e=>_.has(e)),...[..._.keys()].filter(e=>!S.includes(e)).sort()],x=h.find(e=>e.id===a.draft_base),C=h.length?`
      <details class="morph-customize-group" data-morph-group="base" ${v.has(`base`)?`open`:``}>
        <summary><span>Body Type</span><strong>${j(x?.display_name||`Choose`)}</strong></summary>
        <div class="morph-base-options">
          ${h.map(e=>`
            <button type="button" class="morph-base-option ${e.id===a.draft_base?`is-selected`:``}" data-base-id="${j(e.id)}" aria-pressed="${e.id===a.draft_base}" ${!s||a.is_saving?`disabled`:``}>
              <span aria-hidden="true"></span>${j(e.display_name)}
            </button>`).join(``)}
        </div>
      </details>`:``,w=b.map(e=>{let t=_.get(e),n=t.find(e=>a.draft_parts.includes(e.id)||a.draft_face===e.id);return`
        <details class="morph-customize-group" data-morph-group="${j(e)}" ${v.has(e)?`open`:``}>
          <summary><span>${j(M(e))}</span><strong>${j(n?.display_name||`None`)}</strong></summary>
          <label class="morph-customize-field">
            <span class="sr-only">${j(M(e))}</span>
            <select data-morph-kind="${j(e)}" ${!s||a.is_saving?`disabled`:``}>
              <option value="">None</option>
              ${t.map(e=>`<option value="${j(e.id)}" ${n?.id===e.id?`selected`:``}>${j(e.display_name)}</option>`).join(``)}
            </select>
          </label>
        </details>`}).join(``);if(n.innerHTML=C+w||`<p class="morph-empty">Customize options will appear here.</p>`,t.querySelectorAll(`[data-preset-id]`).forEach(e=>e.addEventListener(`click`,()=>{d=null,o.dispatch({type:`select_morph_preset`,preset_id:e.dataset.presetId})})),n.querySelectorAll(`[data-base-id]`).forEach(e=>e.addEventListener(`click`,()=>{d=null,o.dispatch({type:`set_morph_part`,asset_id:e.dataset.baseId})})),n.querySelectorAll(`details`).forEach(e=>e.addEventListener(`toggle`,()=>{e.open?v.add(e.dataset.morphGroup):v.delete(e.dataset.morphGroup)})),n.querySelectorAll(`select`).forEach(e=>e.addEventListener(`change`,()=>{if(d=null,e.value){o.dispatch({type:`set_morph_part`,asset_id:e.value});return}let t=a.assets.find(t=>t.kind===e.dataset.morphKind&&(a.draft_parts.includes(t.id)||a.draft_face===t.id));t&&o.dispatch({type:`clear_morph_part`,asset_id:t.id})})),a.draft_loadout_json)try{f?.setMorphLoadout(JSON.parse(a.draft_loadout_json))}catch{}e.querySelectorAll(`[data-preview-name]`).forEach(e=>{e.textContent=c?.display_name||`Custom morph`}),e.querySelector(`.morph-preview-kind`).textContent=c?`Starter morph`:`Custom morph`,i.disabled=!s||u||a.is_saving||!a.draft_can_save,i.setAttribute(`aria-busy`,String(u||a.is_saving));let T=d??a.feedback;A(r,s?T?.kind===`error`?T.message:u||a.is_saving?`Saving morph…`:T?.message??``:`Please sign in again.`,s?T?.kind===`error`?`error`:u||a.is_saving?`pending`:T?.kind??``:`error`),y(m)};e.querySelectorAll(`[data-morph-tab]`).forEach(e=>{e.addEventListener(`click`,()=>y(e.dataset.morphTab))}),e.querySelectorAll(`[data-preview-action]`).forEach(e=>{e.addEventListener(`click`,()=>f?.play(e.dataset.previewAction))});let x=()=>{g=a?.value.trim().toLowerCase()||``,b(o.snapshot)};a&&(a.value=``,a.addEventListener(`input`,x));let E=o.subscribe(b);T=()=>{p=!0,E(),a?.removeEventListener(`input`,x),f?.destroy(),f=null},b(o.snapshot);try{let t=await h({canvas:e.querySelector(`.morph-preview-canvas`)});p||!e.isConnected?t.destroy():(f=t,b(o.snapshot))}catch{e.querySelectorAll(`[data-preview-name]`).forEach(e=>{e.textContent=`Live preview unavailable`})}e.addEventListener(`submit`,async e=>{if(e.preventDefault(),l()&&!u&&!o.snapshot.appearance.is_saving&&o.snapshot.appearance.draft_can_save){u=!0,d=null,b(o.snapshot);try{if(await o.dispatch({type:`save_appearance`}),o.snapshot.appearance.feedback?.kind===`error`)throw Error(`invalid_appearance`);let e=o.snapshot.appearance.selected_loadout_json;if(e)try{window.localStorage.setItem(`cubacadabra.character-appearance:${encodeURIComponent(C.id)}`,e)}catch{}d={kind:`success`,message:`Morph saved.`}}catch{d={kind:`error`,message:`We couldn’t save your morph. Please try again.`}}finally{u=!1,b(o.snapshot)}}})}function X(){k(!1,`cubes`),_.innerHTML=L(),_.querySelector(`.cube-more-link`)?.addEventListener(`click`,e=>{e.preventDefault(),Z()})}function Z(){k(!1,`cubes`),_.innerHTML=R();let e=_.querySelector(`.cubes-back-link`),t=_.querySelector(`.more-cubes-status`),n=_.querySelector(`.more-cubes-retry`),r=_.querySelector(`.more-cube-table-body`),i=async()=>{t.textContent=`Loading cubes…`,t.dataset.state=`pending`,n.hidden=!0,r.replaceChildren();try{let e=await re();if(e.length===0){t.textContent=`No uploaded cubes yet.`,t.dataset.state=``;return}e.forEach(e=>r.append(ae(e))),t.textContent=``,t.dataset.state=``}catch{t.textContent=`We couldn’t load the uploaded cubes. Please try again.`,t.dataset.state=`error`,n.hidden=!1}};e?.addEventListener(`click`,e=>{e.preventDefault(),X()}),n.addEventListener(`click`,i),i()}async function Q(){k(!1,`blocked-users`),_.innerHTML=z();let e=_.querySelector(`.blocked-users-status`),t=_.querySelector(`.blocked-users-count`),n=_.querySelector(`.blocked-users-retry`);try{let{runtime:r,userIds:i}=await ne();n.hidden=!0,se(r,i,e,t),e.textContent=``,e.dataset.state=``}catch(r){t.textContent=``,e.textContent=oe(r),e.dataset.state=`error`,n.hidden=!1,n.addEventListener(`click`,()=>Q(),{once:!0})}}async function $(){E?.(),E=null,k(!1,`subscription`),_.innerHTML=B();let e=_.querySelector(`.subscription-status`),t=_.querySelector(`.subscription-cancel-link`),n=_.querySelector(`.subscription-start`),r=_.querySelector(`.subscription-checkout-form`),i=_.querySelector(`.subscription-payment`),o=_.querySelector(`.subscription-checkout-status`),s=_.querySelector(`.subscription-submit`),c=new URLSearchParams(window.location.search),l=c.get(`checkout_session_id`),u=c.get(`subscription_return`)===`1`&&l,d=null;n.addEventListener(`click`,async()=>{n.disabled=!0,n.textContent=`Loading payment form…`,e.textContent=`Preparing secure payment…`,e.dataset.state=`pending`;try{let c=await ee();if(!c.client_secret||!c.publishable_key)throw Error(`subscription_checkout_unavailable`);n.hidden=!0,r.hidden=!1,E=a({container:i,form:r,submitButton:s,statusElement:o,clientSecret:c.client_secret,publishableKey:c.publishable_key,onComplete:async n=>{o.textContent=`Finalizing subscription…`,o.dataset.state=`pending`;let i=n?.id?await W(n.id):await U(),a=i?.subscription||i?.membership?.subscription;if(!H(a))throw Error(`subscription_not_active`);d=a,t.hidden=!1,e.textContent=`parent-cadabra is active. Thank you for funding the world.`,e.dataset.state=`success`,r.hidden=!0,o.textContent=``,E?.(),E=null},onError:e=>{o.textContent=e,o.dataset.state=`error`}}),e.textContent=`Enter your payment details below.`,e.dataset.state=``}catch(t){n.disabled=!1,n.textContent=`Try again`,e.textContent=G(t),e.dataset.state=`error`}}),t.addEventListener(`click`,async()=>{if(d?.id&&!t.disabled&&window.confirm(`Cancel your parent-cadabra subscription now?`)){t.disabled=!0,t.textContent=`Cancelling…`,e.textContent=`Cancelling subscription…`,e.dataset.state=`pending`;try{await te(d.id),d=null,r.hidden=!0,E?.(),E=null,t.hidden=!0,t.disabled=!1,t.textContent=`Cancel subscription`,n.hidden=!1,n.disabled=!1,n.textContent=`Continue to payment`,e.textContent=`Subscription canceled. You can subscribe again anytime.`,e.dataset.state=`success`}catch(n){t.disabled=!1,t.textContent=`Cancel subscription`,e.textContent=G(n),e.dataset.state=`error`}}});try{let r=await U(),i=r.subscription;if(H(i)){if(d=i,t.hidden=!1,e.textContent=u?`Finalizing subscription…`:`parent-cadabra is `+V(i)+`.`,e.dataset.state=`success`,u){try{let n=(await W(l))?.subscription;d=n,t.hidden=!H(n),e.textContent=H(n)?`parent-cadabra is active. Thank you for funding the world.`:`Subscription payment needs attention. Please try again.`,e.dataset.state=H(n)?`success`:`error`}catch(t){e.textContent=G(t),e.dataset.state=`error`}c.delete(`subscription_return`),c.delete(`checkout_session_id`);let n=c.toString();window.history.replaceState({},``,window.location.pathname+(n?`?`+n:``)+window.location.hash)}return}if(!r.configured){e.textContent=`Subscriptions are not configured yet.`,e.dataset.state=`error`;return}e.textContent=`No active subscription.`,n.hidden=!1}catch(t){e.textContent=G(t),e.dataset.state=`error`;return}if(u){n.hidden=!0,e.textContent=`Finalizing subscription…`,e.dataset.state=`pending`;try{let t=(await W(l))?.subscription;e.textContent=H(t)?`parent-cadabra is active. Thank you for funding the world.`:`Subscription payment needs attention. Please try again.`,e.dataset.state=H(t)?`success`:`error`}catch(t){n.hidden=!1,n.disabled=!1,n.textContent=`Try again`,e.textContent=G(t),e.dataset.state=`error`}c.delete(`subscription_return`),c.delete(`checkout_session_id`);let t=c.toString();window.history.replaceState({},``,window.location.pathname+(t?`?`+t:``)+window.location.hash)}}v.forEach(e=>{e.addEventListener(`click`,t=>{if(e.hidden){t.preventDefault();return}e.dataset.section===`cubes`?(t.preventDefault(),X()):e.dataset.section===`blocked-users`&&C?(t.preventDefault(),Q()):e.dataset.section===`basics`&&C?(t.preventDefault(),J(C)):e.dataset.section===`morph-editor`&&C?(t.preventDefault(),Y()):e.dataset.section===`subscription`&&C&&(t.preventDefault(),$())})}),i().then(e=>{if(!e){window.location.replace(g);return}r(e),C=e,w=t(e).then(e=>(e.subscribe(e=>{e.account_id===null?C=null:C?.id===e.account_id&&(C={...C,username:e.profile.username})}),e)),w.catch(()=>{}),document.body.dataset.authenticated=`true`;let n=D(e.dob);!e.dob||n===null?ce():n!==null&&n<13?q():window.location.hash===`#cubes`?X():window.location.hash===`#more-cubes`?Z():window.location.hash===`#blocked-users`?Q():window.location.hash===`#subscription`?$():window.location.hash===`#morph-editor`?Y():J(e)}),window.addEventListener(`pagehide`,()=>n()),window.addEventListener(`pageshow`,e=>{e.persisted&&window.location.reload()});