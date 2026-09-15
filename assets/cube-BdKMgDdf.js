import"./modulepreload-polyfill-P2Xu9kJm.js";/* empty css               */import"./mobile-product-nav-CSCi2Eca.js";import{t as e}from"./clientConfig-CHb8n2eX.js";var t=/^(?=.{3,64}$)[a-z0-9]+(?:-[a-z0-9]+)*$/,n=document.querySelector(`#cube-page-root`);function r(){let e=window.location.pathname.match(/^\/cube\/([^/]+)\/?$/);if(!e)return null;try{let n=decodeURIComponent(e[1]);return n.trim()===n&&t.test(n)?n:null}catch{return null}}function i(e){let t=`${e.displayName} · cubacadabra`,n=`Enter ${e.displayName} on cubacadabra.`;document.title=t,document.querySelector(`meta[name="description"]`)?.setAttribute(`content`,n),document.querySelector(`link[rel="canonical"]`)?.setAttribute(`href`,window.location.href)}function a(e){n.innerHTML=`
    <section class="cube-route-message" aria-labelledby="cube-route-error-title">
      <p class="cube-route-kicker">Cube unavailable</p>
      <h1 id="cube-route-error-title">We couldn’t find that cube.</h1>
      <p>${e}</p>
      <a class="cube-route-secondary-action" href="/">Return to cubacadabra</a>
    </section>`}function o(e){let t=e.creator?`@${e.creator}`:`an independent creator`,r=typeof e.playPath==`string`?e.playPath:`/?game=${encodeURIComponent(e.id)}`;i(e),n.innerHTML=`
    <section class="cube-route-hero" aria-labelledby="cube-route-title">
      <div class="cube-route-hero-art" aria-hidden="true">
        <span class="cube-route-orbit cube-route-orbit-one"></span>
        <span class="cube-route-orbit cube-route-orbit-two"></span>
        <span class="cube-route-art-cube"><i></i><i></i><i></i></span>
      </div>
      <div class="cube-route-copy">
        <p class="cube-route-kicker">Playable cube</p>
        <h1 id="cube-route-title">${s(e.displayName)}</h1>
        <p class="cube-route-byline">Created by <strong>${s(t)}</strong></p>
        <p class="cube-route-description">Step into this cubacadabra world and see what its creator built.</p>
        <a class="cube-route-primary-action" href="${c(r)}">
          Enter the cube <span aria-hidden="true">↗</span>
        </a>
      </div>
      <dl class="cube-route-meta">
        <div><dt>Cube ID</dt><dd>${s(e.id)}</dd></div>
        <div><dt>Version</dt><dd>${s(e.version)}</dd></div>
      </dl>
    </section>`}function s(e){return String(e).replaceAll(`&`,`&amp;`).replaceAll(`<`,`&lt;`).replaceAll(`>`,`&gt;`).replaceAll(`"`,`&quot;`).replaceAll(`'`,`&#39;`)}function c(e){return s(e)}async function l(t){let n=await fetch(e(`/cubes/${encodeURIComponent(t)}`),{headers:{Accept:`application/json`}}),r=await n.json().catch(()=>null);if(!n.ok||!r?.cube)throw Error(r?.error||`cube_not_found`);return r.cube}async function u(){let e=r();if(!e){a(`Cube links use a lowercase ID with letters, numbers, and single dashes.`);return}try{o(await l(e))}catch(e){console.error(e),a(`The cube may have been removed, or it may not have been published yet.`)}}u();