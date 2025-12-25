import { NavLink, useNavigate } from 'react-router-dom';
import { getAuth, signOut } from 'firebase/auth';
import { LayoutDashboard, AlertTriangle, PlayCircle, Clock, CheckCircle, Shield, LogOut, ShieldCheck } from 'lucide-react';
import './Sidebar.css';

const Sidebar = ({ userRole, isOpen }) => {
  const navigate = useNavigate();
  const auth = getAuth();

  const handleLogout = async () => {
    await signOut(auth);
    navigate('/login');
  };

  const navItems = [
    { path: "/", icon: <LayoutDashboard size={20} />, label: "Dashboard" },
    { path: "/issues/new", icon: <AlertTriangle size={20} />, label: "New Issues" },
    { path: "/issues/in-progress", icon: <PlayCircle size={20} />, label: "In Progress" },
    { path: "/issues/on-hold", icon: <Clock size={20} />, label: "On Hold" },
    { path: "/issues/resolved", icon: <CheckCircle size={20} />, label: "Resolved Archive" },
  ];

  if (userRole === 'superadmin') {
    navItems.push({ path: "/manage-authorities", icon: <Shield size={20} />, label: "Manage Authorities" });
  }

  return (
    <aside className={`sidebar ${isOpen ? 'open' : 'closed'}`}>
      <div className="sidebar-header">
        <ShieldCheck className="sidebar-logo" />
        <h2 className="sidebar-header-text">Authority Portal</h2>
      </div>
      <nav>
        <ul className="sidebar-nav">
          {navItems.map(item => (
            <li key={item.path}>
              <NavLink to={item.path} className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`} end>
                {item.icon}
                <span className="nav-label">{item.label}</span>
              </NavLink>
            </li>
          ))}
        </ul>
      </nav>
      <div className="sidebar-footer">
        <button onClick={handleLogout} className="logout-button">
          <LogOut size={20} />
          <span className="nav-label">Logout</span>
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;