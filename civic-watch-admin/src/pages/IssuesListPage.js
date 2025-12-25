import { useState, useEffect, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { getFirestore, collection, query, where, onSnapshot, doc, updateDoc, deleteDoc } from 'firebase/firestore';
import { getFunctions, httpsCallable } from 'firebase/functions';
import Modal from '../components/Modal';
import { Eye, Edit } from 'lucide-react';
import '../styles/Table.css';

const IssuesListPage = ({ statusFilter, zone, title }) => {
  const [issues, setIssues] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedIssue, setSelectedIssue] = useState(null);
  const [modalContent, setModalContent] = useState('menu');
  const [resolutionDetails, setResolutionDetails] = useState('');
  const db = getFirestore();
  const functions = getFunctions();

  useEffect(() => {
    let q;
    if (!zone) {
      // Superadmin: show all issues with the given status
      q = query(collection(db, 'issues'), where('status', 'in', statusFilter));
    } else {
      q = query(collection(db, 'issues'), where('issueZone', '==', zone), where('status', 'in', statusFilter));
    }
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const issuesData = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setIssues(issuesData.sort((a, b) => (b.timestamp?.seconds || 0) - (a.timestamp?.seconds || 0)));
      setIsLoading(false);
    }, (error) => {
      console.error("Error fetching issues: ", error);
      setIsLoading(false);
    });
    return () => unsubscribe();
  }, [zone, statusFilter, db]);

  const groupedIssues = useMemo(() => {
    const groups = {};
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    const isSameDay = (d1, d2) => d1.getFullYear() === d2.getFullYear() && d1.getMonth() === d2.getMonth() && d1.getDate() === d2.getDate();
    issues.forEach(issue => {
      const issueDate = issue.timestamp?.toDate();
      if (!issueDate) return;
      let groupKey;
      if (isSameDay(issueDate, today)) groupKey = 'Today';
      else if (isSameDay(issueDate, yesterday)) groupKey = 'Yesterday';
      else groupKey = issueDate.toLocaleDateString(undefined, { year: 'numeric', month: 'long', day: 'numeric' });
      if (!groups[groupKey]) groups[groupKey] = [];
      groups[groupKey].push(issue);
    });
    return groups;
  }, [issues]);

  const openModal = (issue) => {
    setSelectedIssue(issue);
    setModalContent('menu');
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setSelectedIssue(null);
    setResolutionDetails('');
  };

  const handleStatusUpdate = async (newStatus) => {
    if (!selectedIssue) return;
    try {
      await updateDoc(doc(db, 'issues', selectedIssue.id), { status: newStatus });
    } catch (error) {
      console.error("Failed to update status:", error);
      alert("Error: Could not update status.");
    }
    closeModal();
  };

  const handleResolve = async () => {
    if (!selectedIssue) return;
    try {
      const resolveIssue = httpsCallable(functions, 'resolveIssue');
      await resolveIssue({ issueId: selectedIssue.id, resolutionDetails });
    } catch (error) {
      console.error("Failed to resolve issue:", error);
      alert("Error: Could not resolve issue.");
    }
    closeModal();
  };

  const handleReject = async () => {
    if (!selectedIssue) return;
    try {
      await deleteDoc(doc(db, 'issues', selectedIssue.id));
    } catch (error) {
      console.error("Failed to reject issue:", error);
      alert("Error: Could not reject issue.");
    }
    closeModal();
  };

  const renderModalContent = () => {
    switch (modalContent) {
      case 'resolve':
        return (
          <div className="modal-actions">
            <label htmlFor="resolution">Resolution Details (Optional)</label>
            <textarea id="resolution" value={resolutionDetails} onChange={(e) => setResolutionDetails(e.target.value)} />
            <button className="button" onClick={handleResolve}>Mark as Resolved</button>
          </div>
        );
      case 'reject':
        return (
          <div className="modal-actions">
            <p>Are you sure you want to reject and permanently delete this issue? This action cannot be undone.</p>
            <button className="button" onClick={handleReject}>Yes, Reject and Delete</button>
          </div>
        );
      case 'menu':
      default:
        return (
          <div className="modal-actions">
            <p>Select a new status for this issue.</p>
            <button className="button" onClick={() => handleStatusUpdate('Approved')}>Approve</button>
            <button className="button" onClick={() => handleStatusUpdate('InProgress')}>Set to In Progress</button>
            <button className="button" onClick={() => handleStatusUpdate('OnHold')}>Place On Hold</button>
            <hr style={{margin: '24px 0'}}/>
            <button className="button" onClick={() => setModalContent('resolve')}>Resolve Issue...</button>
            <button className="button" onClick={() => setModalContent('reject')}>Reject (Delete) Issue...</button>
          </div>
        );
    }
  };

  if (isLoading) {
    return (
        <div className="page-container">
            <h1>{title}</h1>
            <div className="card no-issues-card"><p>Loading issues...</p></div>
        </div>
    );
  }

  return (
    <div className="page-container">
      <h1>{title}</h1>
      {Object.keys(groupedIssues).length === 0 ? (
        <div className="card no-issues-card"><p>No issues found in this category.</p></div>
      ) : (
        Object.entries(groupedIssues).map(([date, issuesInGroup]) => (
          <div key={date} className="date-group">
            <h3 className="date-group-header">{date}</h3>
            <div className="card issues-table-container">
              <table className="issues-table">
                <thead>
                  <tr><th>Issue Type</th><th>Reported By</th><th>Status</th><th>Actions</th></tr>
                </thead>
                <tbody>
                  {issuesInGroup.map(issue => (
                    <tr key={issue.id}>
                      <td>{issue.issueType}</td>
                      <td className="issue-reporter-cell">
                        <span className="reporter-name">{issue.userName}</span>
                        <span className="reporter-date">{issue.timestamp?.toDate().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                      </td>
                      <td><span className={`status-badge status-${issue.status}`}>{issue.status}</span></td>
                      <td>
                        <Link to={`/issue/${issue.id}`} className="icon-button"><Eye size={18}/></Link>
                        <button onClick={() => openModal(issue)} className="icon-button"><Edit size={18}/></button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        ))
      )}
      <Modal isOpen={isModalOpen} onClose={closeModal} title={`Update Issue: ${selectedIssue?.issueType}`}>
        {renderModalContent()}
      </Modal>
    </div>
  );
};

export default IssuesListPage;