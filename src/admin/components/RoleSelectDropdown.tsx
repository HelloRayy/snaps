import { useState, useRef, useEffect } from 'react';

export type UserRole = 'user' | 'admin' | 'buyer' | 'seller';

interface RoleSelectDropdownProps {
  currentRole: UserRole;
  onChangeRole: (newRole: UserRole) => void;
  disabled?: boolean;
}

const ROLE_OPTIONS = [
  {
    id: 'user' as const,
    title: 'Siswa / Warga Sekolah',
    desc: 'Akses penuh C2C: bebas beli & jual produk, posting utas sosial, dan transaksi COD.',
    icon: 'fa-user-graduate',
    badgeBg: '#dffcf0',
    badgeColor: '#1f845a',
  },
  {
    id: 'admin' as const,
    title: 'Staff Admin',
    desc: 'Akses penuh ke portal manajemen, moderasi konten, dan sistem sekolah.',
    icon: 'fa-shield-halved',
    badgeBg: '#e9f2ff',
    badgeColor: '#0c66e4',
  },
];

export function RoleSelectDropdown({
  currentRole,
  onChangeRole,
  disabled = false,
}: RoleSelectDropdownProps) {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  const normalizedRole = currentRole === 'buyer' || currentRole === 'seller' ? 'user' : currentRole;
  const selectedOption =
    ROLE_OPTIONS.find((opt) => opt.id === normalizedRole) || ROLE_OPTIONS[0];

  useEffect(() => {
    const handleOutsideClick = (e: MouseEvent) => {
      if (
        containerRef.current &&
        !containerRef.current.contains(e.target as Node)
      ) {
        setIsOpen(false);
      }
    };

    if (isOpen) {
      document.addEventListener('mousedown', handleOutsideClick);
    }
    return () => {
      document.removeEventListener('mousedown', handleOutsideClick);
    };
  }, [isOpen]);

  const handleSelect = (role: UserRole) => {
    if (disabled || role === normalizedRole) {
      setIsOpen(false);
      return;
    }
    onChangeRole(role);
    setIsOpen(false);
  };

  return (
    <div ref={containerRef} style={{ position: 'relative', width: '100%' }}>
      {/* Dropdown Input Trigger */}
      <button
        type="button"
        disabled={disabled}
        onClick={() => setIsOpen((prev) => !prev)}
        style={{
          width: '100%',
          height: '44px',
          padding: '0 14px',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          background: '#ffffff',
          border: isOpen ? '1.5px solid #0c66e4' : '1px solid #dcdfe4',
          borderRadius: '4px',
          boxShadow: isOpen
            ? '0 0 0 2px rgba(12, 102, 228, 0.2)'
            : 'none',
          cursor: disabled ? 'not-allowed' : 'pointer',
          opacity: disabled ? 0.6 : 1,
          transition: 'all 150ms ease',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div
            style={{
              width: '26px',
              height: '26px',
              borderRadius: '3px',
              background: selectedOption.badgeBg,
              color: selectedOption.badgeColor,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: '12px',
            }}
          >
            <i className={`fa-solid ${selectedOption.icon}`}></i>
          </div>
          <span style={{ fontSize: '13px', fontWeight: 600, color: '#172b4d' }}>
            {selectedOption.title}
          </span>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <span
            className={`ads-lozenge ${selectedOption.id === 'admin' ? 'ads-lozenge-inprogress' : 'ads-lozenge-success'}`}
            style={{ fontSize: '10px' }}
          >
            {selectedOption.id}
          </span>
          <i
            className="fa-solid fa-chevron-down"
            style={{
              fontSize: '12px',
              color: '#64748b',
              transform: isOpen ? 'rotate(180deg)' : 'rotate(0deg)',
              transition: 'transform 200ms ease',
            }}
          ></i>
        </div>
      </button>

      {/* Dropdown Menu (When Open) */}
      {isOpen && (
        <div
          style={{
            position: 'absolute',
            top: 'calc(100% + 4px)',
            left: 0,
            right: 0,
            zIndex: 100,
            background: '#ffffff',
            border: '1px solid #dcdfe4',
            borderRadius: '4px',
            boxShadow: '0 4px 8px -2px rgba(9, 30, 66, 0.15), 0 0 1px 1px rgba(9, 30, 66, 0.12)',
            padding: '4px',
            display: 'flex',
            flexDirection: 'column',
            gap: '2px',
          }}
        >
          {ROLE_OPTIONS.map((opt) => {
            const isSelected = opt.id === normalizedRole;
            return (
              <div
                key={opt.id}
                onClick={() => handleSelect(opt.id)}
                style={{
                  display: 'flex',
                  alignItems: 'flex-start',
                  justifyContent: 'space-between',
                  padding: '8px 10px',
                  borderRadius: '3px',
                  cursor: 'pointer',
                  background: isSelected ? '#e9f2ff' : 'transparent',
                  border: isSelected ? '1px solid #cce0ff' : '1px solid transparent',
                  transition: 'background-color 100ms ease',
                }}
                onMouseEnter={(e) => {
                  if (!isSelected) e.currentTarget.style.background = '#f1f2f4';
                }}
                onMouseLeave={(e) => {
                  if (!isSelected) e.currentTarget.style.background = 'transparent';
                }}
              >
                <div style={{ display: 'flex', gap: '10px' }}>
                  <div
                    style={{
                      width: '28px',
                      height: '28px',
                      borderRadius: '6px',
                      background: opt.badgeBg,
                      color: opt.badgeColor,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '12px',
                      flexShrink: 0,
                      marginTop: '2px',
                    }}
                  >
                    <i className={`fa-solid ${opt.icon}`}></i>
                  </div>
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <span
                        style={{
                          fontSize: '13px',
                          fontWeight: 600,
                          color: isSelected ? '#1e40af' : '#1f2937',
                        }}
                      >
                        {opt.title}
                      </span>
                    </div>
                    <p
                      style={{
                        margin: '2px 0 0',
                        fontSize: '11.5px',
                        color: isSelected ? '#3b82f6' : '#64748b',
                        lineHeight: 1.4,
                      }}
                    >
                      {opt.desc}
                    </p>
                  </div>
                </div>

                {isSelected && (
                  <div
                    style={{
                      color: '#2563eb',
                      fontSize: '13px',
                      paddingTop: '4px',
                      paddingRight: '4px',
                    }}
                  >
                    <i className="fa-solid fa-check"></i>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
