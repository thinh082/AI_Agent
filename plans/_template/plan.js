document.addEventListener("DOMContentLoaded", () => {
  const storageKey = "plan-checks::" + window.location.pathname;
  const saved = JSON.parse(localStorage.getItem(storageKey) || "{}");

  // 1. Thu gọn / mở rộng từng mục
  document.querySelectorAll(".card-header").forEach((header) => {
    header.addEventListener("click", () => {
      const card = header.closest(".card");
      card.classList.toggle("collapsed");
      const icon = header.querySelector(".toggle-icon");
      if (icon) icon.textContent = card.classList.contains("collapsed") ? "▶ Mở" : "▼ Thu gọn";
    });
  });

  // 2. Nút mở hết / thu gọn hết
  const btnExpand = document.getElementById("btn-expand-all");
  const btnCollapse = document.getElementById("btn-collapse-all");
  if (btnExpand) {
    btnExpand.addEventListener("click", () => {
      document.querySelectorAll(".card").forEach((c) => {
        c.classList.remove("collapsed");
        const icon = c.querySelector(".toggle-icon");
        if (icon) icon.textContent = "▼ Thu gọn";
      });
    });
  }
  if (btnCollapse) {
    btnCollapse.addEventListener("click", () => {
      document.querySelectorAll(".card").forEach((c) => {
        c.classList.add("collapsed");
        const icon = c.querySelector(".toggle-icon");
        if (icon) icon.textContent = "▶ Mở";
      });
    });
  }

  // 3. Lưu trạng thái checkbox vào localStorage
  document.querySelectorAll("ul.checklist input[type='checkbox'], table.checklist-table input[type='checkbox']").forEach((cb, idx) => {
    const key = cb.id || "cb-" + idx;
    if (saved[key]) {
      cb.checked = true;
      cb.closest("li")?.classList.add("done");
    }
    cb.addEventListener("change", () => {
      cb.closest("li")?.classList.toggle("done", cb.checked);
      saved[key] = cb.checked;
      localStorage.setItem(storageKey, JSON.stringify(saved));
    });
  });

  // 4. Tự gắn nút Copy vào mọi thẻ <pre>
  document.querySelectorAll("pre").forEach((pre) => {
    const btn = document.createElement("button");
    btn.className = "copy-btn";
    btn.textContent = "Copy";
    btn.addEventListener("click", async () => {
      const text = pre.querySelector("code")?.innerText || pre.innerText;
      try {
        await navigator.clipboard.writeText(text);
        btn.textContent = "Đã copy!";
        setTimeout(() => (btn.textContent = "Copy"), 1500);
      } catch {
        btn.textContent = "Lỗi copy";
      }
    });
    pre.appendChild(btn);
  });
});
