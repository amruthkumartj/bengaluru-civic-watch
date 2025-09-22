import { useState, useEffect } from 'react';
import { initializeApp } from 'firebase/app';
import {
  getAuth,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
  getIdTokenResult,
  sendPasswordResetEmail, // <-- Import the new function
} from 'firebase/auth';
import {
  getFirestore,
  collection,
  query,
  where,
  onSnapshot,
  doc,
  updateDoc,
} from 'firebase/firestore';
import { getFunctions, httpsCallable } from 'firebase/functions';

// IMPORTANT: MAKE SURE YOUR FIREBASE CONFIG IS CORRECT
const firebaseConfig = {
  apiKey: "AIzaSyBQXhZNQKYypxkrOop9PhsALNeLTCY0A0s",
  authDomain: "fixmyooru.firebaseapp.com",
  projectId: "fixmyooru",
  storageBucket: "fixmyooru.firebasestorage.app",
  messagingSenderId: "745464196938",
  appId: "1:745464196938:web:9db27e065828cd14cddbb3",
  measurementId: "G-EM5BVGZPC7"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const functions = getFunctions(app);

function App() {
  const [user, setUser] = useState(null);
  const [userClaims, setUserClaims] = useState({});
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
      if (currentUser) {
        const tokenResult = await getIdTokenResult(currentUser);
        setUser(currentUser);
        setUserClaims(tokenResult.claims);
      } else {
        setUser(null);
        setUserClaims({});
      }
      setIsLoading(false);
    });
    return () => unsubscribe();
  }, []);

  if (isLoading) {
    return <div className="loading-screen"><h1>Loading Admin Panel...</h1></div>;
  }

  return (
    <div className="app-container">
      {user ? (
        <Dashboard user={user} role={userClaims.role} zone={userClaims.zone} />
      ) : (
        <LoginScreen />
      )}
    </div>
  );
}

function LoginScreen() {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [message, setMessage] = useState('');

    const handleLogin = async (e) => {
        e.preventDefault();
        setError('');
        setMessage('');
        try {
            await signInWithEmailAndPassword(auth, email, password);
        } catch (err) {
            setError('Failed to log in. Please check your credentials.');
        }
    };

    const handlePasswordReset = async () => {
        setError('');
        setMessage('');
        if (!email) {
            setError('Please enter your email address above before clicking the link.');
            return;
        }
        try {
            await sendPasswordResetEmail(auth, email);
            setMessage('Password setup link sent! Please check your email inbox.');
        } catch (err) {
            setError('Could not send email. Please verify the address is correct.');
        }
    };

    return (
        <div className="login-container">
            <form onSubmit={handleLogin} className="login-form">
                <h2>Civic Watch Admin Login</h2>
                <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="Email"
                    required
                />
                <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Password"
                    required
                />
                <button type="submit">Log In</button>
                {error && <p className="error-message">{error}</p>}
                {message && <p className="status-message">{message}</p>}
                <div className="password-reset-container">
                  <span onClick={handlePasswordReset} className="password-reset-link">
                    Forgot Password?
                  </span>
                </div>
            </form>
        </div>
    );
}

function Dashboard({ user, role, zone }) {
    return (
        <div>
            <header className="dashboard-header">
                <h1>Admin Dashboard</h1>
                <div>
                    <span>{user.email} ({role || 'No Role'})</span>
                    <button onClick={() => signOut(auth)} className="logout-btn">Logout</button>
                </div>
            </header>
            <main className="dashboard-main">
                {role === 'superadmin' && <SuperAdminDashboard />}
                {role === 'authority' && <AuthorityDashboard zone={zone} />}
                {!role && <p>You do not have a role assigned. Please contact support.</p>}
            </main>
        </div>
    );
}

function SuperAdminDashboard() {
  const [authorityName, setAuthorityName] = useState('');
  const [authorityEmail, setAuthorityEmail] = useState('');
  const [authorityPhone, setAuthorityPhone] = useState('');
  const [authorityZone, setAuthorityZone] = useState('BLRN');
  const [message, setMessage] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleCreateAuthority = async (e) => {
    e.preventDefault();
    setMessage('');
    setIsSubmitting(true);
    try {
      const createAuthority = httpsCallable(functions, 'createAuthority');
      const result = await createAuthority({
        name: authorityName,
        email: authorityEmail,
        phone: authorityPhone,
        zone: authorityZone,
      });
      setMessage(result.data.result);
      setAuthorityName('');
      setAuthorityEmail('');
      setAuthorityPhone('');
    } catch (error) {
      setMessage(`Error: ${error.message}`);
    }
    setIsSubmitting(false);
  };

  return (
    <div className="dashboard-section">
      <h2>Super Admin Controls</h2>
      <form onSubmit={handleCreateAuthority} className="create-authority-form card">
        <h3>Create New Zonal Authority</h3>
        <input value={authorityName} onChange={e => setAuthorityName(e.target.value)} placeholder="Full Name" required/>
        <input type="email" value={authorityEmail} onChange={e => setAuthorityEmail(e.target.value)} placeholder="Email" required/>
        <input value={authorityPhone} onChange={e => setAuthorityPhone(e.target.value)} placeholder="Phone Number (Optional)"/>
        <select value={authorityZone} onChange={e => setAuthorityZone(e.target.value)}>
          <option value="BLRN">North (BLRN)</option>
          <option value="BLRS">South (BLRS)</option>
          <option value="BLRE">East (BLRE)</option>
          <option value="BLRW">West (BLRW)</option>
          <option value="BLRNE">North-East (BLRNE)</option>
          <option value="BLRSE">South-East (BLRSE)</option>
          <option value="BLRC">Central (BLRC)</option>
        </select>
        <button type="submit" disabled={isSubmitting}>
          {isSubmitting ? 'Creating...' : 'Create Authority'}
        </button>
        {message && <p className="status-message">{message}</p>}
      </form>
    </div>
  );
}

function AuthorityDashboard({ zone }) {
  const [issues, setIssues] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (!zone) return;
    const issuesRef = collection(db, 'issues');
    const q = query(issuesRef, where('issueZone', '==', zone));

    const unsubscribe = onSnapshot(q, (querySnapshot) => {
      const issuesData = [];
      querySnapshot.forEach((doc) => {
        issuesData.push({ id: doc.id, ...doc.data() });
      });
      setIssues(issuesData);
      setIsLoading(false);
    }, (error) => {
        console.error("Error fetching issues: ", error);
        setIsLoading(false);
    });

    return () => unsubscribe();
  }, [zone]);

  const handleStatusChange = async (issueId, newStatus) => {
    const issueRef = doc(db, 'issues', issueId);
    try {
      await updateDoc(issueRef, { status: newStatus });
    } catch (error) {
      console.error("Error updating status: ", error);
    }
  };

  return (
    <div className="dashboard-section">
      <h2>Issue Dashboard for Zone: {zone}</h2>
      {isLoading && <p>Loading issues...</p>}
      {!isLoading && issues.length === 0 && <p>No issues found for your zone.</p>}
      <div className="issues-list">
        {issues.map(issue => (
          <div key={issue.id} className="issue-card card">
            <img src={issue.imageUrl} alt={issue.issueType} className="issue-image" />
            <div className="issue-details">
              <h3>{issue.issueType}</h3>
              <p><strong>Reported by:</strong> {issue.userName}</p>
              <p><strong>Status:</strong> <span className={`status status-${issue.status.toLowerCase()}`}>{issue.status}</span></p>
              <p><strong>Date:</strong> {issue.timestamp?.toDate().toLocaleString()}</p>
              <div className="status-actions">
                <select
                  value={issue.status}
                  onChange={(e) => handleStatusChange(issue.id, e.target.value)}
                >
                  <option value="Submitted">Submitted</option>
                  <option value="Approved">Approved</option>
                  <option value="InProgress">In Progress</option>
                  <option value="Resolved">Resolved</option>
                  <option value="Rejected">Rejected</option>
                </select>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default App;

