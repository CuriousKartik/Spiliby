// Empty states are an invitation to act, not a dead end.
// Drop your own PNG illustrations into src/assets/images and swap the
// `icon` prop usage below for an <img src={...} /> once assets are ready.
export default function EmptyState({ icon: Icon, image, title, message, action }) {
  return (
    <div className="flex flex-col items-center justify-center text-center px-8 py-14">
      {image ? (
        <img src={image} alt="" className="w-20 h-20 object-contain mb-5" />
      ) : (
        <div className="w-20 h-20 rounded-3xl bg-dusty-denim-100 dark:bg-deep-space-blue-300 flex items-center justify-center mb-5">
          {Icon && <Icon size={34} strokeWidth={1.5} className="text-blue-slate-500 dark:text-dusty-denim-500" />}
        </div>
      )}
      <h3 className="font-display font-semibold text-lg text-ink-black-500 dark:text-eggshell-600">{title}</h3>
      {message && <p className="text-sm text-blue-slate-500 dark:text-dusty-denim-600 mt-1.5 max-w-[240px]">{message}</p>}
      {action && <div className="mt-5">{action}</div>}
    </div>
  );
}
