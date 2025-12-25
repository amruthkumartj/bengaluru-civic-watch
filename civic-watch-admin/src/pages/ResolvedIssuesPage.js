import { useState, useEffect, useMemo } from 'react';
import { getFirestore, collection, query, where, onSnapshot } from 'firebase/firestore';
import '../styles/Table.css';

const ResolvedIssuesPage = ({ zone }) => {
  const [issues, setIssues] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const db = getFirestore();

  useEffect(() => {
    let q;
    if (!zone) {
      // Superadmin: show all resolved issues
      q = query(collection(db, 'resolved_issues'));
    } else {
      q = query(collection(db, 'resolved_issues'), where('issueZone', '==', zone));
    }
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const issuesData = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setIssues(issuesData.sort((a, b) => (b.resolvedAt?.seconds || 0) - (a.resolvedAt?.seconds || 0)));
      setIsLoading(false);
    }, (error) => {
      console.error("Error fetching resolved issues: ", error);
      setIsLoading(false);
    });
    return () => unsubscribe();
  }, [zone, db]);

  const groupedIssues = useMemo(() => {
    const groups = {};
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    
    const isSameDay = (d1, d2) => d1.getFullYear() === d2.getFullYear() && d1.getMonth() === d2.getMonth() && d1.getDate() === d2.getDate();

    issues.forEach(issue => {
      const resolvedDate = issue.resolvedAt?.toDate();
      if (!resolvedDate) return;

      let groupKey;
      if (isSameDay(resolvedDate, today)) {
        groupKey = 'Today';
      } else if (isSameDay(resolvedDate, yesterday)) {
        groupKey = 'Yesterday';
      } else {
        groupKey = resolvedDate.toLocaleDateString(undefined, { year: 'numeric', month: 'long', day: 'numeric' });
      }

      if (!groups[groupKey]) {
        groups[groupKey] = [];
      }
      groups[groupKey].push(issue);
    });
    return groups;
  }, [issues]);

  if (isLoading) {
    return (
        <div className="page-container">
            <h1>Resolved Issues Archive</h1>
            <p>This is a historical record of all issues that have been successfully resolved in your zone.</p>
            <div className="card no-issues-card"><p>Loading resolved issues...</p></div>
        </div>
    );
  }

  return (
    <div className="page-container">
      <h1>Resolved Issues Archive</h1>
      <p>This is a historical record of all issues that have been successfully resolved in your zone.</p>
      
      {Object.keys(groupedIssues).length === 0 ? (
        <div className="card no-issues-card">
          <p>No resolved issues found in your zone.</p>
        </div>
      ) : (
        Object.entries(groupedIssues).map(([date, issuesInGroup]) => (
          <div key={date} className="date-group">
            <h3 className="date-group-header">{date}</h3>
            <div className="card issues-table-container">
              <table className="issues-table">
                <thead>
                  <tr>
                    <th>Issue Type</th>
                    <th>Reported By</th>
                    <th>Resolved On</th>
                    <th>Resolution Details</th>
                  </tr>
                </thead>
                <tbody>
                  {issuesInGroup.map(issue => (
                    <tr key={issue.id}>
                      <td>{issue.issueType}</td>
                      <td>{issue.userName || 'N/A'}</td>
                      <td className="resolved-date">{issue.resolvedAt?.toDate().toLocaleTimeString()}</td>
                      <td>{issue.resolutionDetails || 'No details provided.'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        ))
      )}
    </div>
  );
};

export default ResolvedIssuesPage;