export default function Card({ children, className = '', onClick }) {
  const interactive = typeof onClick === 'function';
  return (
    <div
      onClick={onClick}
      className={`rounded-3xl bg-white dark:bg-deep-space-blue-400 shadow-[0_2px_16px_-4px_rgba(13,19,33,0.08)] dark:shadow-none border border-dusty-denim-100/60 dark:border-deep-space-blue-300 p-4 ${interactive ? 'active:scale-[0.98] transition-transform cursor-pointer' : ''} ${className}`}
    >
      {children}
    </div>
  );
}
