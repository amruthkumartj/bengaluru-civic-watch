import { Menu, Sun, Moon } from 'lucide-react';
import './Header.css';

const Header = ({ userEmail, onToggleSidebar, theme, onToggleTheme }) => {
  return (
    <header className="header">
      <div className="header-left">
        <button onClick={onToggleSidebar} className="icon-button">
          <Menu />
        </button>
      </div>
      <div className="header-right">
        <button onClick={onToggleTheme} className="icon-button theme-toggle">
          {theme === 'light' ? <Moon /> : <Sun />}
        </button>
        <div className="header-user">
          <div className="user-avatar">{userEmail?.charAt(0).toUpperCase()}</div>
          <span>{userEmail}</span>
        </div>
      </div>
    </header>
  );
};

export default Header;