import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { getFirestore, doc, onSnapshot } from 'firebase/firestore';
import { getFunctions, httpsCallable } from 'firebase/functions';
import './IssueDetailPage.css';

const IssueDetailPage = () => {
  const { issueId } = useParams();
  const navigate = useNavigate();
  const [issue, setIssue] = useState(null);
  const [reporter, setReporter] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const db = getFirestore();
  const functions = getFunctions();

  useEffect(() => {
    const issueRef = doc(db, 'issues', issueId);
    const unsubscribe = onSnapshot(issueRef, (docSnap) => {
      if (docSnap.exists()) {
        const issueData = { id: docSnap.id, ...docSnap.data() };
        setIssue(issueData);
        if (issueData.userId) {
          const getUserDetails = httpsCallable(functions, 'getUserDetails');
          getUserDetails({ userId: issueData.userId })
            .then(result => setReporter(result.data))
            .catch(err => console.error("Could not fetch user details", err));
        }
      } else {
        navigate('/issues/new');
      }
      setIsLoading(false);
    });
    return () => unsubscribe();
  }, [issueId, db, navigate, functions]);

  if (isLoading || !issue) {
    return <div className="page-container"><h2>Loading Issue Details...</h2></div>;
  }

  return (
    <div className="page-container">
      <h1>Issue Detail: {issue.issueType}</h1>
      <div className="issue-detail-grid">
        <div className="issue-detail-left-col">
          <img src={issue.imageUrl} alt={issue.issueType} />
          <a
            href={`https://www.google.com/maps/search/?api=1&query=${issue.location?.latitude},${issue.location?.longitude}`}
            target="_blank"
            rel="noopener noreferrer"
            className="button"
          >
            View Location on Map
          </a>
        </div>
        <div className="issue-detail-right-col">
          <div className="card issue-detail-info-card">
            <h3>Issue Information</h3>
            <dl className="detail-list">
              <dt>Status</dt><dd>{issue.status}</dd>
              <dt>Zone</dt><dd>{issue.issueZone}</dd>
              <dt>Reported On</dt><dd>{issue.timestamp?.toDate().toLocaleString()}</dd>
            </dl>
          </div>
          <div className="card issue-detail-info-card" style={{marginTop: '24px'}}>
            <h3>Reporter Details</h3>
            {reporter ? (
              <dl className="detail-list">
                <dt>Name</dt><dd>{reporter.name}</dd>
                <dt>Email</dt><dd>{reporter.email}</dd>
                <dt>Phone</dt><dd>{reporter.phone}</dd>
                <dt>Address</dt><dd>{reporter.address || 'Not Provided'}</dd>
              </dl>
            ) : <p>Loading reporter details...</p>}
          </div>
        </div>
      </div>
    </div>
  );
};

export default IssueDetailPage;