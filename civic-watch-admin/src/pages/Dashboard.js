import { useState, useEffect } from 'react';
import { getFirestore, collection, query, where, onSnapshot, Timestamp } from 'firebase/firestore';
import { ResponsiveContainer, PieChart, Pie, Cell, Legend } from 'recharts';
import { Link } from 'react-router-dom';
import { ArrowRight, ListChecks } from 'lucide-react';
import './Dashboard.css';

const DashboardPage = ({ userClaims }) => {
  const [stats, setStats] = useState({ active: 0, resolved: 0 });
  const [todaysIssues, setTodaysIssues] = useState([]);
  const db = getFirestore();

  useEffect(() => {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayStartTimestamp = Timestamp.fromDate(todayStart);

    let qToday, qActive, qResolved;
    if (userClaims.role === 'superadmin') {
      qToday = query(collection(db, 'issues'), where('status', '==', 'Submitted'), where('timestamp', '>=', todayStartTimestamp));
      qActive = query(collection(db, 'issues'));
      qResolved = query(collection(db, 'resolved_issues'));
    } else if (userClaims.zone) {
      qToday = query(collection(db, 'issues'), where('issueZone', '==', userClaims.zone), where('status', '==', 'Submitted'), where('timestamp', '>=', todayStartTimestamp));
      qActive = query(collection(db, 'issues'), where('issueZone', '==', userClaims.zone));
      qResolved = query(collection(db, 'resolved_issues'), where('issueZone', '==', userClaims.zone));
    } else {
      return;
    }

    const unsubToday = onSnapshot(qToday, (snapshot) => {
      setTodaysIssues(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });
    const unsubActive = onSnapshot(qActive, (snapshot) => {
      setStats(prev => ({ ...prev, active: snapshot.size }));
    });
    const unsubResolved = onSnapshot(qResolved, (snapshot) => {
      setStats(prev => ({ ...prev, resolved: snapshot.size }));
    });

    return () => {
      unsubToday();
      unsubActive();
      unsubResolved();
    };
  }, [userClaims.zone, userClaims.role, db]);

  const chartData = [
    { name: 'Active Issues', value: stats.active },
    { name: 'Resolved Issues', value: stats.resolved },
  ];
  const COLORS = ['#FF8042', '#0088FE'];
  const totalIssues = stats.active + stats.resolved;

  return (
    <div className="page-container dashboard-page">
      <h1>Welcome, {userClaims.role} ({userClaims.zone})</h1>
      <div className="dashboard-grid">
        <div className="card large-card">
            <div className="card-background-icon"><ListChecks /></div>
            <h3>Today's New Issues ({todaysIssues.length})</h3>
            <div className="recent-issues-list">
                {todaysIssues.length > 0 ? (
                    todaysIssues.map(issue => (
                        <Link to={`/issue/${issue.id}`} key={issue.id} className="recent-issue-item">
                           <div className="issue-info">
                                <span className="issue-type">{issue.issueType}</span>
                                <span className="issue-time">{issue.timestamp?.toDate().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                           </div>
                           <ArrowRight size={16} />
                        </Link>
                    ))
                ) : <p className="no-issues-message">No new issues submitted in your zone today.</p>}
            </div>
            <div className="card-footer">
              <p>All new issues submitted on {new Date().toLocaleDateString()} are listed here.</p>
            </div>
        </div>
        <div className="card">
          <h3>Zone Performance</h3>
          <div className="chart-wrapper">
            <div className="chart-center-text">
              {totalIssues > 0 ? (
                <>
                  <span className="chart-number">{stats.resolved}</span>
                  <span className="chart-total">/ {totalIssues} Resolved</span>
                </>
              ) : ( <span>No Data</span> )}
            </div>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={chartData} cx="50%" cy="50%" innerRadius={80} outerRadius={100} fill="#8884d8" paddingAngle={5} dataKey="value">
                    {chartData.map((entry, index) => ( <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} /> ))}
                </Pie>
                <Legend iconType="circle" />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="quick-shortcuts">
            <h4>Quick Shortcuts</h4>
            <Link to="/issues/in-progress" className="shortcut-link">View In Progress Issues</Link>
            <Link to="/issues/resolved" className="shortcut-link">Browse Resolved Archive</Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DashboardPage;