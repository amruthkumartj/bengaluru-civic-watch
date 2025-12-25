import { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { initializeApp } from 'firebase/app';
import { getAuth, onAuthStateChanged, getIdTokenResult } from 'firebase/auth';

import Sidebar from './components/Sidebar';
import Header from './components/Header';
import DashboardPage from './pages/Dashboard';
import IssuesListPage from './pages/IssuesListPage';
import IssueDetailPage from './pages/IssueDetailPage';
import ResolvedIssuesPage from './pages/ResolvedIssuesPage';
import LoginPage from './pages/Login';
import SuperAdminPage from './pages/SuperAdmin';
import './App.css';

// Using Environment Variables for Firebase Config
const firebaseConfig = {
  apiKey: process.env.REACT_APP_FIREBASE_API_KEY,
  authDomain: process.env.REACT_APP_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.REACT_APP_FIREBASE_PROJECT_ID,
  storageBucket: process.env.REACT_APP_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.REACT_APP_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.REACT_APP_FIREBASE_APP_ID,
};

initializeApp(firebaseConfig);
const auth = getAuth();

function App() {
  const [user, setUser] = useState(null);
  const [userClaims, setUserClaims] = useState({});
  const [isLoading, setIsLoading] = useState(true);
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [theme, setTheme] = useState(localStorage.getItem('theme') || 'light');

  useEffect(() => {
    document.body.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
  }, [theme]);

  const toggleTheme = () => {
    setTheme(prevTheme => prevTheme === 'light' ? 'dark' : 'light');
  };

  useEffect(() => {
    const checkUser = onAuthStateChanged(auth, async (currentUser) => {
      if (currentUser) {
        const tokenResult = await getIdTokenResult(currentUser, true);
        setUser(currentUser);
        setUserClaims(tokenResult.claims);
      } else {
        setUser(null);
        setUserClaims({});
      }
      setIsLoading(false);
    });
    return () => checkUser();
  }, []);

  if (isLoading) {
    return <div className="loading-screen"><h1>Loading...</h1></div>;
  }

  if (!user) {
    return <LoginPage />;
  }

  const zoneProp = userClaims.role === 'superadmin' ? null : userClaims.zone;
  return (
    <Router>
      <div className={`app-layout ${isSidebarOpen ? 'sidebar-open' : 'sidebar-closed'}`}>
        <Sidebar userRole={userClaims.role} isOpen={isSidebarOpen} />
        <div className="main-content-wrapper">
          <Header
            userEmail={user.email}
            onToggleSidebar={() => setIsSidebarOpen(!isSidebarOpen)}
            theme={theme}
            onToggleTheme={toggleTheme}
          />
          <main className="main-content">
            <Routes>
              <Route path="/login" element={<Navigate to="/" />} />
              <Route path="/" element={<DashboardPage userClaims={userClaims} />} />
              <Route path="/issues/new" element={<IssuesListPage statusFilter={["Submitted"]} zone={zoneProp} title="New Issues" />} />
              <Route path="/issues/on-hold" element={<IssuesListPage statusFilter={["OnHold"]} zone={zoneProp} title="On Hold Issues" />} />
              <Route path="/issues/in-progress" element={<IssuesListPage statusFilter={["Approved", "InProgress"]} zone={zoneProp} title="Ongoing Resolutions" />} />
              <Route path="/issues/resolved" element={<ResolvedIssuesPage zone={zoneProp} />} />
              <Route path="/issue/:issueId" element={<IssueDetailPage />} />
              {userClaims.role === 'superadmin' && <Route path="/manage-authorities" element={<SuperAdminPage />} />}
              <Route path="*" element={<Navigate to="/" />} />
            </Routes>
          </main>
        </div>
      </div>
    </Router>
  );
}

export default App;