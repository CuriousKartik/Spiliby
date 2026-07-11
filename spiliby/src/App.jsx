import { useEffect } from 'react';
import { HashRouter, Routes, Route, Navigate } from 'react-router-dom';
import useStore from './store/useStore';
import Layout from './components/Layout';
import Onboarding from './pages/Onboarding';
import Home from './pages/Home';
import Groups from './pages/Groups';
import GroupDetails from './pages/GroupDetails';
import Friends from './pages/Friends';
import Settings from './pages/Settings';

export default function App() {
  const ready = useStore((s) => s.ready);
  const profile = useStore((s) => s.profile);
  const init = useStore((s) => s.init);

  useEffect(() => { init(); }, [init]);

  if (!ready) return null;

  if (!profile) return <Onboarding />;

  return (
    <HashRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<Home />} />
          <Route path="/groups" element={<Groups />} />
          <Route path="/groups/:groupId" element={<GroupDetails />} />
          <Route path="/friends" element={<Friends />} />
          <Route path="/settings" element={<Settings />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Route>
      </Routes>
    </HashRouter>
  );
}
