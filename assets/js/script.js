/**
 * ALMEIDA CONFESSOR ADVOCACIA & CONSULTORIA JURÍDICA
 * Script Principal - Interações e Acessibilidade (Etapa 01)
 */

document.addEventListener('DOMContentLoaded', () => {
  const header = document.getElementById('header');
  const mobileBtn = document.getElementById('mobile-menu-btn');
  const mobileNav = document.getElementById('mobile-nav');
  const mobileLinks = document.querySelectorAll('.mobile-nav-link');

  // 1. Efeito de Scroll no Header
  const handleScroll = () => {
    if (window.scrollY > 20) {
      header.classList.add('scrolled');
    } else {
      header.classList.remove('scrolled');
    }
  };

  window.addEventListener('scroll', handleScroll, { passive: true });
  handleScroll();

  // 2. Toggle do Menu Mobile
  const toggleMobileMenu = () => {
    const isExpanded = mobileBtn.getAttribute('aria-expanded') === 'true';
    const nextState = !isExpanded;

    mobileBtn.setAttribute('aria-expanded', String(nextState));
    mobileBtn.classList.toggle('active', nextState);

    mobileNav.setAttribute('aria-hidden', String(!nextState));
    mobileNav.classList.toggle('open', nextState);
  };

  const closeMobileMenu = () => {
    mobileBtn.setAttribute('aria-expanded', 'false');
    mobileBtn.classList.remove('active');
    mobileNav.setAttribute('aria-hidden', 'true');
    mobileNav.classList.remove('open');
  };

  if (mobileBtn && mobileNav) {
    mobileBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      toggleMobileMenu();
    });

    // Fechar ao clicar em qualquer link de navegação interna
    mobileLinks.forEach((link) => {
      link.addEventListener('click', () => {
        closeMobileMenu();
      });
    });

    // Fechar com tecla ESC
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && mobileNav.classList.contains('open')) {
        closeMobileMenu();
        mobileBtn.focus();
      }
    });

    // Fechar se clicar fora do menu
    document.addEventListener('click', (e) => {
      if (
        mobileNav.classList.contains('open') &&
        !mobileNav.contains(e.target) &&
        !mobileBtn.contains(e.target)
      ) {
        closeMobileMenu();
      }
    });
  }

  // 3. Animações Sutis de Scroll (Fade-in com deslocamento suave)
  const revealElements = document.querySelectorAll('.reveal-on-scroll');
  if (revealElements.length > 0) {
    if ('IntersectionObserver' in window) {
      const revealObserver = new IntersectionObserver(
        (entries, observer) => {
          entries.forEach((entry) => {
            if (entry.isIntersecting) {
              entry.target.classList.add('is-visible');
              observer.unobserve(entry.target);
            }
          });
        },
        {
          root: null,
          rootMargin: '0px 0px -40px 0px',
          threshold: 0.12,
        }
      );

      revealElements.forEach((el) => revealObserver.observe(el));
    } else {
      revealElements.forEach((el) => el.classList.add('is-visible'));
    }
  }

  // 4. Scrollspy de Navegação Ativa
  const sections = document.querySelectorAll('main#inicio, section#escritorio, section#areas, section#equipe, section#contato');
  const desktopLinks = document.querySelectorAll('.desktop-nav .nav-link');
  const drawerLinks = document.querySelectorAll('.mobile-nav-list .mobile-nav-link');

  if ('IntersectionObserver' in window && sections.length > 0) {
    const observerOptions = {
      root: null,
      rootMargin: '-20% 0px -60% 0px',
      threshold: 0
    };

    const setActiveLink = (id) => {
      desktopLinks.forEach((link) => {
        link.classList.toggle('active', link.getAttribute('href') === `#${id}`);
      });
      drawerLinks.forEach((link) => {
        link.classList.toggle('active', link.getAttribute('href') === `#${id}`);
      });
    };

    const spyObserver = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          const currentId = entry.target.id;
          setActiveLink(currentId);
        }
      });
    }, observerOptions);

    sections.forEach((sec) => spyObserver.observe(sec));
  }
});

