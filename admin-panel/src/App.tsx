import { useEffect, useState } from 'react';
import axios from 'axios';
import './App.css';

interface Stats {
  activeDrivers: number;
  totalRevenue: number;
  totalRides: number;
}

interface Driver {
  id: string;
  name: string;
  phone: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  isOnline: boolean;
  rating?: number;
}

function App() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchData = async () => {
    try {
      const [statsRes, driversRes] = await Promise.all([
        axios.get('https://toto-ride.onrender.com/api/admin/stats'),
        axios.get('https://toto-ride.onrender.com/api/admin/drivers')
      ]);
      setStats(statsRes.data);
      setDrivers(driversRes.data);
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 30000);
    return () => clearInterval(interval);
  }, []);

  const handleStatusUpdate = async (id: string, status: 'APPROVED' | 'REJECTED') => {
    try {
      await axios.post(`https://toto-ride.onrender.com/api/admin/driver/${id}/status`, { status });
      // Optimistic update or refetch
      fetchData();
    } catch (error) {
      console.error('Error updating status:', error);
      alert('Failed to update status');
    }
  };

  return (
    <div className="dashboard-container">
      <header className="header">
        <h1>🚕 Toto Ride Admin</h1>
        <div className="user-profile">Admin User</div>
      </header>

      <main className="main-content">
        <h2>Overview</h2>

        {loading && !stats ? (
          <p>Loading data...</p>
        ) : stats ? (
          <>
            <div className="stats-grid">
              <div className="stat-card">
                <h3>Active Drivers</h3>
                <p className="stat-value">{stats.activeDrivers}</p>
              </div>
              <div className="stat-card">
                <h3>Total Revenue</h3>
                <p className="stat-value">₹{stats.totalRevenue.toFixed(2)}</p>
              </div>
              <div className="stat-card">
                <h3>Total Rides</h3>
                <p className="stat-value">{stats.totalRides}</p>
              </div>
            </div>

            <div className="sections-container">
              <div className="section">
                <h3>Driver Management</h3>
                {drivers.length === 0 ? (
                  <p>No registered drivers.</p>
                ) : (
                  <table className="driver-table">
                    <thead>
                      <tr>
                        <th>Name</th>
                        <th>Phone</th>
                        <th>Status</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {drivers.map(driver => (
                        <tr key={driver.id}>
                          <td>{driver.name}</td>
                          <td>{driver.phone}</td>
                          <td>
                            <span className={`status-badge ${driver.status.toLowerCase()}`}>
                              {driver.status}
                            </span>
                          </td>
                          <td>
                            {driver.status === 'PENDING' && (
                              <div className="action-buttons">
                                <button
                                  className="btn-approve"
                                  onClick={() => handleStatusUpdate(driver.id, 'APPROVED')}
                                >Approve</button>
                                <button
                                  className="btn-reject"
                                  onClick={() => handleStatusUpdate(driver.id, 'REJECTED')}
                                >Reject</button>
                              </div>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            </div>
          </>
        ) : (
          <p className="error-text">Failed to load system data.</p>
        )}
      </main>
    </div>
  );
}

export default App;
