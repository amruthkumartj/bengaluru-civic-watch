import { useState, useEffect } from 'react';
import { getFirestore, collection, onSnapshot } from 'firebase/firestore';
import { getFunctions, httpsCallable } from 'firebase/functions';
import { UserPlus } from 'lucide-react';
import './SuperAdmin.css';
import '../styles/Table.css';

const SuperAdminPage = () => {
  const [authorities, setAuthorities] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [authorityName, setAuthorityName] = useState('');
  const [authorityEmail, setAuthorityEmail] = useState('');
  const [authorityPhone, setAuthorityPhone] = useState('');
  const [authorityZone, setAuthorityZone] = useState('BLRN');
  const [message, setMessage] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  const db = getFirestore();
  const functions = getFunctions();

  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'authorities'), (snapshot) => {
      setAuthorities(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setIsLoading(false);
    });
    return () => unsub();
  }, [db]);
  
  const handleCreateAuthority = async (e) => {
    e.preventDefault();
    setMessage('');
    setIsSubmitting(true);
    try {
      const createAuthority = httpsCallable(functions, 'createAuthority');
      const result = await createAuthority({
        name: authorityName, email: authorityEmail, phone: authorityPhone, zone: authorityZone,
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
    <div className="page-container">
      <h1>Manage Authorities</h1>
      <div className="superadmin-container">
        <div className="card">
          <h3>Create New Zonal Authority</h3>
          <form onSubmit={handleCreateAuthority} className="authority-form">
            <div className="input-group">
              <input id="name" value={authorityName} onChange={e => setAuthorityName(e.target.value)} required placeholder=" "/>
              <label htmlFor="name">Full Name</label>
            </div>
            <div className="input-group">
              <input id="email-create" type="email" value={authorityEmail} onChange={e => setAuthorityEmail(e.target.value)} required placeholder=" "/>
              <label htmlFor="email-create">Email</label>
            </div>
            <div className="input-group">
              <input id="phone" value={authorityPhone} onChange={e => setAuthorityPhone(e.target.value)} placeholder=" "/>
              <label htmlFor="phone">Phone (Optional)</label>
            </div>
            <div className="select-wrapper">
              <label htmlFor="zone">Zone</label>
              <select id="zone" value={authorityZone} onChange={e => setAuthorityZone(e.target.value)}>
                <option value="BLRN">North (BLRN)</option>
                <option value="BLRS">South (BLRS)</option>
                <option value="BLRE">East (BLRE)</option>
                <option value="BLRW">West (BLRW)</option>
                <option value="BLRNE">North-East (BLRNE)</option>
                <option value="BLRSE">South-East (BLRSE)</option>
                <option value="BLRC">Central (BLRC)</option>
              </select>
            </div>
            <button type="submit" className="button" disabled={isSubmitting}>
              <UserPlus size={16} /> {isSubmitting ? 'Creating...' : 'Create Authority'}
            </button>
            {message && <p>{message}</p>}
          </form>
        </div>

        <div className="card">
          <h3>Existing Authorities</h3>
          <div className="issues-table-container">
            <table className="issues-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Email</th>
                  <th>Zone</th>
                </tr>
              </thead>
              <tbody>
                {isLoading && <tr><td colSpan="3">Loading...</td></tr>}
                {authorities.map(auth => (
                  <tr key={auth.id}>
                    <td>{auth.name}</td>
                    <td>{auth.email}</td>
                    <td>{auth.zone}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SuperAdminPage;