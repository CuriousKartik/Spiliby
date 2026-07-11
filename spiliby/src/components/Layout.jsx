import { NavLink, Outlet } from 'react-router-dom';
import { Home, Users, UsersRound, Settings } from 'lucide-react';

const tabs = [
  { to: '/', label: 'Home', icon: Home, end: true },
  { to: '/groups', label: 'Groups', icon: UsersRound },
  { to: '/friends', label: 'Friends', icon: Users },
  { to: '/settings', label: 'Settings', icon: Settings },
];

export default function Layout() {
  return (
    <div className="min-h-screen flex flex-col dark:bg-ink-black-400">
      <main className="flex-1 max-w-lg mx-auto w-full px-4 pt-6 pb-32">
        <Outlet />
        <p className="mt-6 text-center text-[11px] text-dusty-denim-500 dark:text-dusty-denim-600">
          Made with <span className="text-red-500">♥</span> by Kartikey & Junaid
        </p>
        <p className="mt-2 text-center text-[10px] text-dusty-denim-400 dark:text-dusty-denim-500">
          Free to use · no passwords · no copying as your own
        </p>
      </main>
      <nav className="fixed bottom-0 inset-x-0 bg-white/90 dark:bg-deep-space-blue-400/90 backdrop-blur-md border-t border-dusty-denim-100 dark:border-deep-space-blue-300 safe-bottom">
        <div className="max-w-lg mx-auto flex justify-around py-2">
          {tabs.map(({ to, label, icon: Icon, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) =>
                `flex flex-col items-center gap-1 px-4 py-1.5 rounded-2xl transition-colors ${
                  isActive
                    ? 'text-blue-slate-600 dark:text-dusty-denim-500'
                    : 'text-dusty-denim-500 dark:text-blue-slate-500'
                }`
              }
            >
              <Icon size={22} strokeWidth={2} />
              <span className="text-[11px] font-medium">{label}</span>
            </NavLink>
          ))}
        </div>
      </nav>
    </div>
  );
}
