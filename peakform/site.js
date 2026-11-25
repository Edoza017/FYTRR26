const tabList = document.querySelector('.screen-tabs');
const tabs = Array.from(tabList.querySelectorAll('[role="tab"]'));

function showScreen(selectedTab) {
  for (const tab of tabs) {
    const isSelected = tab === selectedTab;
    tab.setAttribute('aria-selected', String(isSelected));
    tab.tabIndex = isSelected ? 0 : -1;
    document.getElementById(tab.getAttribute('aria-controls')).hidden = !isSelected;
  }
}

for (const [index, tab] of tabs.entries()) {
  tab.addEventListener('click', () => showScreen(tab));
  tab.addEventListener('keydown', event => {
    const destinations = {
      ArrowDown: (index + 1) % tabs.length,
      ArrowUp: (index + tabs.length - 1) % tabs.length,
      Home: 0,
      End: tabs.length - 1,
    };
    if (!(event.key in destinations)) return;

    event.preventDefault();
    const nextTab = tabs[destinations[event.key]];
    showScreen(nextTab);
    nextTab.focus();
  });
}
tabList.hidden = false;
