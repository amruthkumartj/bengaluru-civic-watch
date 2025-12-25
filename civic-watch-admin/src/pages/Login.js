import { useState } from 'react';
import { getAuth, signInWithEmailAndPassword, sendPasswordResetEmail } from 'firebase/auth';

const LoginPage = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const auth = getAuth();

  const handleLogin = async (e) => {
    e.preventDefault();
    if (!email || !password) {
      return setError('Please enter both email and password.');
    }
    setIsLoading(true);
    setError('');
    setMessage('');
    try {
      await signInWithEmailAndPassword(auth, email, password);
    } catch (err) {
      setError('Failed to sign in. Please check your credentials.');
    }
    setIsLoading(false);
  };
  
  const handlePasswordReset = async () => {
    if (!email) {
      return setError('Please enter your email address first.');
    }
    setIsLoading(true);
    setError('');
    setMessage('');
    try {
      await sendPasswordResetEmail(auth, email);
      setMessage('Password reset email sent! Check your inbox.');
    } catch (error) {
      setError('Could not send password reset email.');
    }
    setIsLoading(false);
  };

return (
    <div className="login-page-wrapper">
      <div className="login-form-container">
        <div className="login-header">
          <div className="logo-icon">
             <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
          </div>
          <h2>Admin Panel</h2>
          <p>Bengaluru Civic Watch</p>
        </div>
        <form onSubmit={handleLogin}>
          <div className="input-group">
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder=" "
              required
            />
            <label htmlFor="email">Email</label>
          </div>
          <div className="input-group">
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder=" "
              required
            />
            <label htmlFor="password">Password</label>
          </div>
          {error && <p className="error-message">{error}</p>}
          {message && <p className="status-message">{message}</p>}
          <button type="submit" className="button" disabled={isLoading}>
            {isLoading ? 'Signing In...' : 'Sign In'}
          </button>
        </form>
        <div className="login-footer">
            <span onClick={handlePasswordReset} className="password-reset-link">
                First time login / Forgot Password?
            </span>
        </div>
      </div>
    </div>
  );
}

export default LoginPage;