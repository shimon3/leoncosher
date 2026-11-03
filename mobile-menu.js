(function(){
 const toggle=document.getElementById('mobile-nav-toggle');
 const nav=document.getElementById('nav');
 if(!toggle||!nav)return;
 toggle.addEventListener('click',()=>{
  const open=toggle.getAttribute('aria-expanded')!=='true';
  toggle.setAttribute('aria-expanded',String(open));
  document.body.classList.toggle('mobile-nav-open',open);
 });
 nav.addEventListener('click',e=>{if(e.target.closest('button')){document.body.classList.remove('mobile-nav-open');toggle.setAttribute('aria-expanded','false')}});
})();
