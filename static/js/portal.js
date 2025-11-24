(function () {
    // ---------- Debug / verbose logging ----------
    const VERBOSE =
        window.QUIZ_VERBOSE === true ||
        window.QUIZ_VERBOSE === "1" ||
        window.QUIZ_VERBOSE === "true";

    function dbg(...args) {
        if (VERBOSE) {
            console.log("[portal]", ...args);
        }
    }

    dbg("portal.js loaded");

    // ---------- Theme handling (still in localStorage) ----------
    const themeToggle = document.getElementById("theme-toggle");
    const storedTheme = window.localStorage.getItem("quiz_theme");
    if (storedTheme === "dark") {
        document.body.classList.add("dark");
        dbg("Theme set to dark (from localStorage)");
    }

    themeToggle.addEventListener("click", function () {
        document.body.classList.toggle("dark");
        const isDark = document.body.classList.contains("dark");
        window.localStorage.setItem("quiz_theme", isDark ? "dark" : "light");
        dbg("Theme toggled, now:", isDark ? "dark" : "light");
    });

    // ---------- Simple cookie helpers for DNI ----------
    function setCookie(name, value, days) {
        dbg("setCookie", name, value, days);
        let expires = "";
        if (typeof days === "number") {
            const date = new Date();
            date.setTime(date.getTime() + days * 24 * 60 * 60 * 1000);
            expires = "; expires=" + date.toUTCString();
        }
        document.cookie =
            name +
            "=" +
            encodeURIComponent(value) +
            expires +
            "; path=/; SameSite=Lax";
    }

    function getCookie(name) {
        const nameEQ = name + "=";
        const ca = document.cookie.split(";");
        for (let i = 0; i < ca.length; i++) {
            let c = ca[i];
            while (c.charAt(0) === " ") c = c.substring(1, c.length);
            if (c.indexOf(nameEQ) === 0) {
                const val = decodeURIComponent(c.substring(nameEQ.length, c.length));
                dbg("getCookie", name, "=", val);
                return val;
            }
        }
        dbg("getCookie", name, "not found");
        return null;
    }

    function deleteCookie(name) {
        dbg("deleteCookie", name);
        document.cookie =
            name +
            "=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/; SameSite=Lax";
    }

    // ---------- Navigation buttons ----------
    const homeBtn = document.getElementById("btn-home");
    const logoutBtn = document.getElementById("btn-logout");

    homeBtn.addEventListener("click", function () {
        dbg("Home button clicked");
        window.location.href = "/";
    });

    logoutBtn.addEventListener("click", function () {
        dbg("Logout button clicked");
        // Clear DNI cookie and reset dashboard
        deleteCookie("quiz_dni");
        currentDni = null;
        currentRole = null;
        dashboard.classList.add("hidden");
        studentInfo.textContent = "";
        attemptsTableBody.innerHTML = "";
        if (attemptsChart) {
            attemptsChart.destroy();
            attemptsChart = null;
        }
        dniInput.value = "";
        errorDiv.textContent = "";
        randomInfo.textContent = "";
        podiumInfo.textContent = "";
        deleteTestInfo.textContent = "";
        analyticsOutput.textContent = "";
        teacherPanel.classList.add("hidden");
    });

    // ---------- DOM references ----------
    const dniInput = document.getElementById("student-dni");
    const loadDashboardBtn = document.getElementById("load-dashboard");
    const errorDiv = document.getElementById("error");
    const dashboard = document.getElementById("dashboard");
    const studentInfo = document.getElementById("student-info");
    const testSelect = document.getElementById("test-select");
    const startSelectedBtn = document.getElementById("start-selected-test");
    const numQuestionsInput = document.getElementById("num-questions");
    const createRandomBtn = document.getElementById("create-random-test");
    const randomInfo = document.getElementById("random-info");
    const attemptsEmpty = document.getElementById("attempts-empty");
    const attemptsTableWrapper = document.getElementById("attempts-table-wrapper");
    const attemptsTableBody = document.getElementById("attempts-table-body");
    const attemptsChartCanvas = document.getElementById("attempts-chart");

    const viewPodiumBtn = document.getElementById("view-podium-btn");
    const podiumInfo = document.getElementById("podium-info");

    const teacherPanel = document.getElementById("teacher-panel");
    const deleteTestBtn = document.getElementById("delete-test-btn");
    const deleteTestInfo = document.getElementById("delete-test-info");
    const loadAnalyticsBtn = document.getElementById("load-analytics-btn");
    const analyticsOutput = document.getElementById("analytics-output");

    let currentDni = null;
    let currentRole = null;
    let attemptsChart = null;

    function showError(msg) {
        errorDiv.textContent = msg;
        dbg("ERROR:", msg);
    }

    // ---------- API helpers ----------
    async function fetchAvailableTests() {
        dbg("fetchAvailableTests() start");
        const resp = await fetch("/available_tests");
        dbg("fetchAvailableTests() status", resp.status);
        if (!resp.ok) {
            const txt = await resp.text();
            dbg("fetchAvailableTests() error body:", txt);
            throw new Error("Error fetching tests: " + txt);
        }
        const data = await resp.json();
        dbg("fetchAvailableTests() data:", data);
        return data;
    }

    async function fetchStudentAttempts(dni) {
        dbg("fetchStudentAttempts() for DNI", dni);
        const resp = await fetch(`/student/${encodeURIComponent(dni)}/attempts`);
        dbg("fetchStudentAttempts() status", resp.status);
        if (!resp.ok) {
            const txt = await resp.text();
            dbg("fetchStudentAttempts() error body:", txt);
            throw new Error("Error fetching attempts: " + txt);
        }
        const data = await resp.json();
        dbg("fetchStudentAttempts() data:", data);
        return data;
    }

    async function fetchAnalytics(testId) {
        dbg("fetchAnalytics() for test", testId);
        const resp = await fetch(`/tests/${encodeURIComponent(testId)}/analytics`);
        dbg("fetchAnalytics() status", resp.status);
        if (!resp.ok) {
            const txt = await resp.text();
            dbg("fetchAnalytics() error body:", txt);
            throw new Error("Error fetching analytics: " + txt);
        }
        const data = await resp.json();
        dbg("fetchAnalytics() data:", data);
        return data;
    }

    // ---------- UI helpers ----------
    function populateTestsSelect(tests) {
        dbg("populateTestsSelect() with", tests ? tests.length : 0, "tests");
        testSelect.innerHTML = "";
        if (!tests || tests.length === 0) {
            const opt = document.createElement("option");
            opt.value = "";
            opt.textContent = "No tests available";
            testSelect.appendChild(opt);
            testSelect.disabled = true;
            startSelectedBtn.disabled = true;
            viewPodiumBtn.disabled = true;
            return;
        }
        testSelect.disabled = false;
        startSelectedBtn.disabled = false;
        viewPodiumBtn.disabled = false;

        tests.forEach((t) => {
            const opt = document.createElement("option");
            opt.value = String(t.id);
            const label = `#${t.id} – ${t.title} (${t.num_questions} q)`;
            opt.textContent = label;
            testSelect.appendChild(opt);
        });
    }

    function renderAttemptsTable(attempts) {
        dbg("renderAttemptsTable() attempts:", attempts ? attempts.length : 0);
        attemptsTableBody.innerHTML = "";
        if (!attempts || attempts.length === 0) {
            attemptsEmpty.classList.remove("hidden");
            attemptsTableWrapper.classList.add("hidden");
            return;
        }
        attemptsEmpty.classList.add("hidden");
        attemptsTableWrapper.classList.remove("hidden");

        attempts.forEach((a) => {
            const tr = document.createElement("tr");
            const date = a.submitted_at ? a.submitted_at.substring(0, 10) : "";
            const pct = a.percentage != null ? a.percentage.toFixed(1) : "";
            const score =
                a.score != null && a.max_score != null
                    ? `${a.score.toFixed(2)}/${a.max_score.toFixed(2)}`
                    : "";

            tr.innerHTML = `
                <td>${date}</td>
                <td>${a.test_title}</td>
                <td>${a.attempt_number}</td>
                <td>${score}</td>
                <td>${pct}</td>
                <td>${a.status}</td>
            `;
            attemptsTableBody.appendChild(tr);
        });
    }

    function renderAttemptsChart(attempts) {
        dbg("renderAttemptsChart() attempts:", attempts ? attempts.length : 0);
        const graded = (attempts || []).filter((a) => a.percentage != null);
        const labels = graded.map((a, idx) => `#${a.attempt_number} (${idx + 1})`);
        const data = graded.map((a) => a.percentage);

        if (attemptsChart) {
            attemptsChart.destroy();
            attemptsChart = null;
        }

        if (graded.length === 0) {
            dbg("renderAttemptsChart() no graded attempts");
            return;
        }

        const ctx = attemptsChartCanvas.getContext("2d");
        attemptsChart = new Chart(ctx, {
            type: "line",
            data: {
                labels: labels,
                datasets: [
                    {
                        label: "Percentage",
                        data: data,
                        tension: 0.2,
                    },
                ],
            },
            options: {
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100,
                    },
                },
            },
        });
        dbg("renderAttemptsChart() chart created");
    }

    function formatPodiumHtml(analytics) {
        const parts = [];
        const single = analytics.podium_best_single || [];
        const avg = analytics.podium_best_average || [];

        if (single.length > 0) {
            parts.push("<strong>Best single score:</strong>");
            single.forEach((p, idx) => {
                const pct =
                    p.best_percentage != null
                        ? p.best_percentage.toFixed(1) + "%"
                        : "";
                parts.push(`${idx + 1}. ${p.name} – ${pct}`);
            });
        } else {
            parts.push("<strong>Best single score:</strong> no data yet.");
        }

        parts.push("<br>");

        if (avg.length > 0) {
            parts.push("<strong>Best average score:</strong>");
            avg.forEach((p, idx) => {
                const pct =
                    p.avg_percentage != null
                        ? p.avg_percentage.toFixed(1) + "%"
                        : "";
                parts.push(`${idx + 1}. ${p.name} – ${pct}`);
            });
        } else {
            parts.push("<strong>Best average score:</strong> no data yet.");
        }

        return parts.join("<br>");
    }

    // ---------- Load dashboard for a DNI ----------
    async function loadDashboard(dni) {
        dbg("loadDashboard() start for DNI", dni);
        errorDiv.textContent = "";
        randomInfo.textContent = "";
        podiumInfo.textContent = "";
        deleteTestInfo.textContent = "";
        analyticsOutput.textContent = "";

        try {
            const [testsData, attemptsData] = await Promise.all([
                fetchAvailableTests(),
                fetchStudentAttempts(dni),
            ]);

            if (attemptsData.error) {
                dbg("loadDashboard() attemptsData.error", attemptsData.error);
                showError(attemptsData.error);
                return;
            }

            currentDni = dni;
            currentRole = attemptsData.student.role || "student";
            dbg(
                "loadDashboard() success",
                "role=",
                currentRole,
                "attempts=",
                attemptsData.attempts ? attemptsData.attempts.length : 0
            );

            // Save DNI in cookie (1 day). No consent banner, just do it.
            setCookie("quiz_dni", dni, 1);

            dashboard.classList.remove("hidden");
            studentInfo.textContent =
                `${attemptsData.student.name} ` +
                `(DNI: ${attemptsData.student.dni}, ` +
                `${attemptsData.student.email}, role: ${currentRole})`;

            populateTestsSelect(testsData.tests || []);
            renderAttemptsTable(attemptsData.attempts || []);
            renderAttemptsChart(attemptsData.attempts || []);

            // Teacher panel visibility
            if (currentRole === "teacher") {
                dbg("Enabling teacher panel");
                teacherPanel.classList.remove("hidden");
            } else {
                dbg("Hiding teacher panel (role:", currentRole, ")");
                teacherPanel.classList.add("hidden");
            }
        } catch (e) {
            dbg("loadDashboard() exception", e);
            showError(String(e));
        }
    }

    // ---------- Event handlers ----------
    loadDashboardBtn.addEventListener("click", function () {
        const dni = dniInput.value.trim();
        dbg("Load dashboard button clicked, DNI=", dni);
        if (!dni) {
            showError("You must enter your ID (DNI).");
            return;
        }
        loadDashboard(dni);
    });

    startSelectedBtn.addEventListener("click", function () {
        dbg("Start selected test button clicked");
        if (!currentDni) {
            showError("Load your dashboard first.");
            return;
        }
        const testId = testSelect.value;
        if (!testId) {
            showError("Select a test first.");
            return;
        }
        dbg("Navigating to quiz page with test_id=", testId);
        window.location.href = `/quiz?test_id=${encodeURIComponent(testId)}`;
    });

    createRandomBtn.addEventListener("click", async function () {
        randomInfo.textContent = "";
        dbg("Create random test button clicked");
        if (!currentDni) {
            showError("Load your dashboard first.");
            return;
        }
        const n = parseInt(numQuestionsInput.value || "20", 10);
        dbg("Random test num_questions=", n);
        const payload = {
            student_dni: currentDni,
            num_questions: isNaN(n) ? 20 : n,
            course_code: "2526-45810-A",
        };
        try {
            const resp = await fetch("/tests/random_from_bank", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(payload),
            });
            dbg("create_random_test response status", resp.status);
            if (!resp.ok) {
                const txt = await resp.text();
                dbg("create_random_test error body", txt);
                randomInfo.textContent = "Error creating test: " + txt;
                return;
            }
            const data = await resp.json();
            dbg("create_random_test response json", data);
            if (data.error) {
                randomInfo.textContent = data.error;
                return;
            }
            randomInfo.textContent =
                `Created test #${data.test_id} (${data.num_questions} questions). ` +
                `You can now start it from the list.`;

            const testsData = await fetchAvailableTests();
            populateTestsSelect(testsData.tests || []);
        } catch (e) {
            dbg("create_random_test exception", e);
            randomInfo.textContent = "Error creating test: " + e;
        }
    });

    // Podium for everyone
    viewPodiumBtn.addEventListener("click", async function () {
        podiumInfo.textContent = "";
        const testId = testSelect.value;
        dbg("View podium clicked, testId=", testId);
        if (!testId) {
            showError("Select a test first.");
            return;
        }
        try {
            const data = await fetchAnalytics(testId);
            if (data.error) {
                podiumInfo.textContent = data.error;
                return;
            }
            if (!data.analytics) {
                podiumInfo.textContent = "No analytics available yet.";
                return;
            }
            const html = [
                `<strong>Test:</strong> #${data.test.id} – ${data.test.title}`,
                "<br>",
                formatPodiumHtml(data.analytics),
            ].join("<br>");
            podiumInfo.innerHTML = html;
        } catch (e) {
            dbg("viewPodium exception", e);
            podiumInfo.textContent = "Error loading podium: " + e;
        }
    });

    // Teacher: delete test
    deleteTestBtn.addEventListener("click", async function () {
        deleteTestInfo.textContent = "";
        dbg("Delete test button clicked, role=", currentRole);
        if (currentRole !== "teacher") {
            deleteTestInfo.textContent =
                "Only teachers can delete tests (role=teacher).";
            return;
        }
        const testId = testSelect.value;
        if (!testId) {
            deleteTestInfo.textContent = "Select a test first.";
            return;
        }
        if (
            !confirm(
                `Are you sure you want to delete test #${testId} ` +
                    "and ALL associated results? This cannot be undone."
            )
        ) {
            dbg("Delete test canceled by user");
            return;
        }
        try {
            const resp = await fetch(
                `/tests/${encodeURIComponent(
                    testId
                )}?teacher_dni=${encodeURIComponent(currentDni)}`,
                { method: "DELETE" }
            );
            dbg("delete_test response status", resp.status);
            if (!resp.ok) {
                const txt = await resp.text();
                dbg("delete_test error body", txt);
                deleteTestInfo.textContent = "Error deleting test: " + txt;
                return;
            }
            const data = await resp.json();
            dbg("delete_test response json", data);
            if (data.error) {
                deleteTestInfo.textContent = data.error;
                return;
            }
            deleteTestInfo.textContent =
                `Deleted test #${data.deleted_test_id} ` +
                `("${data.deleted_test_title}") ` +
                `– attempts: ${data.deleted_attempts}, ` +
                `answers: ${data.deleted_answers}.`;

            // Refresh tests list
            const testsData = await fetchAvailableTests();
            populateTestsSelect(testsData.tests || []);
        } catch (e) {
            dbg("delete_test exception", e);
            deleteTestInfo.textContent = "Error deleting test: " + e;
        }
    });

    // Teacher: load analytics
    loadAnalyticsBtn.addEventListener("click", async function () {
        analyticsOutput.textContent = "";
        const testId = testSelect.value;
        dbg("Load analytics clicked, testId=", testId);
        if (!testId) {
            analyticsOutput.textContent = "Select a test first.";
            return;
        }
        try {
            const data = await fetchAnalytics(testId);
            if (data.error) {
                analyticsOutput.textContent = data.error;
                return;
            }
            const a = data.analytics;
            if (!a) {
                analyticsOutput.textContent = "No analytics available yet.";
                return;
            }

            const lines = [];
            lines.push(
                `<strong>Test:</strong> #${data.test.id} – ${data.test.title}`
            );
            lines.push("<br>");

            // Questions
            if (a.most_failed_question) {
                const q = a.most_failed_question;
                const wr = q.wrong_rate != null ? (q.wrong_rate * 100).toFixed(1) : "-";
                const cr =
                    q.correct_rate != null ? (q.correct_rate * 100).toFixed(1) : "-";
                lines.push(
                    `<strong>Most failed question:</strong> [Q${q.question_id}] ` +
                        `${q.text} (wrong: ${q.wrong_count} / ${q.total_answers}, ${wr}%)`
                );
            } else {
                lines.push("<strong>Most failed question:</strong> no data yet.");
            }

            if (a.most_correct_question) {
                const q = a.most_correct_question;
                const wr = q.wrong_rate != null ? (q.wrong_rate * 100).toFixed(1) : "-";
                const cr =
                    q.correct_rate != null ? (q.correct_rate * 100).toFixed(1) : "-";
                lines.push(
                    `<strong>Most correct question:</strong> [Q${q.question_id}] ` +
                        `${q.text} (correct: ${q.correct_count} / ${q.total_answers}, ${cr}%)`
                );
            } else {
                lines.push("<strong>Most correct question:</strong> no data yet.");
            }

            lines.push("<br>");

            // Answers
            if (a.most_failed_answer) {
                const o = a.most_failed_answer;
                const wr =
                    o.wrong_rate != null ? (o.wrong_rate * 100).toFixed(1) : "-";
                lines.push(
                    `<strong>Most failed answer:</strong> ` +
                        `"${o.option_text}" (Q${o.question_id}) ` +
                        `– wrong: ${o.wrong_selected} / ${o.times_selected}, ${wr}%`
                );
            } else {
                lines.push("<strong>Most failed answer:</strong> no data yet.");
            }

            if (a.most_correct_answer) {
                const o = a.most_correct_answer;
                const cr =
                    o.correct_rate != null ? (o.correct_rate * 100).toFixed(1) : "-";
                lines.push(
                    `<strong>Most correct answer:</strong> ` +
                        `"${o.option_text}" (Q${o.question_id}) ` +
                        `– correct: ${o.correct_selected} / ${o.times_selected}, ${cr}%`
                );
            } else {
                lines.push("<strong>Most correct answer:</strong> no data yet.");
            }

            lines.push("<br>");

            // Attempts stats
            const s = a.attempts_stats || {};
            const avgAttempts =
                s.avg_attempts_per_student != null
                    ? s.avg_attempts_per_student.toFixed(2)
                    : "-";
            const avgPct =
                s.avg_percentage != null ? s.avg_percentage.toFixed(2) + "%" : "-";

            lines.push(
                `<strong>Attempts:</strong> total ${s.total_attempts || 0}, ` +
                    `students ${s.num_students || 0}, ` +
                    `avg attempts / student ${avgAttempts}, ` +
                    `avg percentage ${avgPct}.`
            );

            lines.push("<br>");
            lines.push(formatPodiumHtml(a));

            analyticsOutput.innerHTML = lines.join("<br>");
        } catch (e) {
            dbg("loadAnalytics exception", e);
            analyticsOutput.textContent = "Error loading analytics: " + e;
        }
    });

    // ---------- On load: read cookie (do NOT auto-load, just prefill) ----------
    const cookieDni = getCookie("quiz_dni");
    if (cookieDni) {
        dbg("Prefilling DNI from cookie:", cookieDni);
        dniInput.value = cookieDni;
    } else {
        dbg("No quiz_dni cookie found on load");
    }
})();

