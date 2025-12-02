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
        themeToggle.textContent = "☀️";
        dbg("Theme set to dark (from localStorage)");
    } else {
        themeToggle.textContent = "🌙";
    }

    themeToggle.addEventListener("click", function () {
        document.body.classList.toggle("dark");
        const isDark = document.body.classList.contains("dark");
        themeToggle.textContent = isDark ? "☀️" : "🌙";
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
    const dashboardBtn = document.getElementById("btn-dashboard");

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
        // Hide dashboard button
        if (dashboardBtn) {
            dashboardBtn.classList.add("hidden");
        }
    });

    // Dashboard button (teacher only)
    if (dashboardBtn) {
        dashboardBtn.addEventListener("click", function () {
            dbg("Dashboard button clicked");
            window.location.href = "/dashboard";
        });
        // Hide by default, will show when teacher logs in
        dashboardBtn.classList.add("hidden");
    }

    // ---------- DOM references ----------
    const dniInput = document.getElementById("student-dni");
    const loadDashboardBtn = document.getElementById("load-dashboard");
    const errorDiv = document.getElementById("error");
    const dashboard = document.getElementById("dashboard");
    const studentInfo = document.getElementById("student-info");
    const testSelect = document.getElementById("test-select");
    const startSelectedBtn = document.getElementById("start-selected-test");
    const numQuestionsInput = document.getElementById("num-questions");
    const maxAttemptsInput = document.getElementById("max-attempts");
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
    const renameTestBtn = document.getElementById("rename-test-btn");
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
        dbg("renderAttemptsTable() with", attempts.length, "attempts");
        attemptsTableBody.innerHTML = "";
        if (attempts.length === 0) {
            attemptsEmpty.classList.remove("hidden");
            attemptsTableWrapper.classList.add("hidden");
            return;
        }
        attemptsEmpty.classList.add("hidden");
        attemptsTableWrapper.classList.remove("hidden");

        attempts.forEach((a) => {
            const row = document.createElement("tr");
            const score = a.score != null ? a.score.toFixed(2) : "-";
            const maxScore = a.max_score != null ? a.max_score.toFixed(2) : "-";
            const percentage = a.percentage != null ? a.percentage.toFixed(1) : "-";
            const submittedStr = a.submitted_at
                ? new Date(a.submitted_at).toLocaleString()
                : "-";

            row.innerHTML = `
                <td>${a.test_title || "N/A"}</td>
                <td>${a.attempt_number}</td>
                <td>${score} / ${maxScore}</td>
                <td>${percentage}%</td>
                <td>${submittedStr}</td>
            `;
            attemptsTableBody.appendChild(row);
        });
    }

    function renderAttemptsChart(attempts) {
        dbg("renderAttemptsChart() with", attempts.length, "attempts");
        if (attemptsChart) {
            attemptsChart.destroy();
            attemptsChart = null;
        }
        if (attempts.length === 0) {
            return;
        }

        const data = attempts.map((a, idx) => ({
            x: idx + 1,
            y: a.percentage != null ? a.percentage : 0,
            label: a.test_title || "N/A",
        }));

        attemptsChart = new Chart(attemptsChartCanvas, {
            type: "line",
            data: {
                labels: data.map((d) => d.x),
                datasets: [
                    {
                        label: "Score %",
                        data: data.map((d) => d.y),
                        borderColor: "rgb(37, 99, 235)",
                        backgroundColor: "rgba(37, 99, 235, 0.1)",
                        tension: 0.2,
                    },
                ],
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false,
                    },
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100,
                        title: {
                            display: true,
                            text: "Score %",
                        },
                    },
                    x: {
                        title: {
                            display: true,
                            text: "Attempt #",
                        },
                    },
                },
            },
        });
    }

    function formatPodiumHtml(analytics) {
        const podBest = analytics.podium_best_single || [];
        const podAvg = analytics.podium_best_average || [];

        const linesBest = ["<strong>🏆 Best single attempt:</strong>"];
        if (podBest.length === 0) {
            linesBest.push("(no data yet)");
        } else {
            podBest.forEach((s, i) => {
                const pct =
                    s.best_percentage != null ? s.best_percentage.toFixed(1) : "-";
                linesBest.push(`${i + 1}. ${s.name} – ${pct}%`);
            });
        }

        const linesAvg = ["<strong>📊 Best average:</strong>"];
        if (podAvg.length === 0) {
            linesAvg.push("(no data yet)");
        } else {
            podAvg.forEach((s, i) => {
                const pct =
                    s.avg_percentage != null ? s.avg_percentage.toFixed(1) : "-";
                linesAvg.push(`${i + 1}. ${s.name} – ${pct}%`);
            });
        }

        return linesBest.join("<br>") + "<br><br>" + linesAvg.join("<br>");
    }

    // ---------- Load dashboard for DNI ----------
    loadDashboardBtn.addEventListener("click", async function () {
        errorDiv.textContent = "";
        randomInfo.textContent = "";
        podiumInfo.textContent = "";
        deleteTestInfo.textContent = "";
        analyticsOutput.textContent = "";

        const dni = dniInput.value.trim();
        dbg("Load dashboard button clicked, DNI=", dni);
        if (!dni) {
            showError("Please enter your DNI.");
            return;
        }

        try {
            // Store DNI in cookie
            setCookie("quiz_dni", dni, 7);
            currentDni = dni;

            // Fetch tests
            const testsData = await fetchAvailableTests();
            let tests = testsData.tests || [];



            populateTestsSelect(tests);

            // Fetch attempts
            const attemptsData = await fetchStudentAttempts(dni);
            if (attemptsData.error) {
                showError(attemptsData.error);
                return;
            }

            const attempts = attemptsData.attempts || [];
            renderAttemptsTable(attempts);
            renderAttemptsChart(attempts);

            // Check role from first attempt (if any)
            currentRole = null;
            if (attempts.length > 0) {
                // We don't have role in attempts, need to get from user
                // For now, check if DNI matches teacher pattern
                // Better: fetch user info from a /user/{dni} endpoint
            }

            // Show dashboard
            dashboard.classList.remove("hidden");

            // Infer role: if DNI matches known teacher pattern, show teacher panel
            // For demo: check if this is a teacher by attempting to fetch teacher dashboard
            try {
                const teacherCheck = await fetch(
                    `/teacher/dashboard_overview?teacher_dni=${encodeURIComponent(dni)}`
                );
                if (teacherCheck.ok) {
                    const teacherData = await teacherCheck.json();
                    if (!teacherData.error) {
                        currentRole = "teacher";
                        teacherPanel.classList.remove("hidden");
                        // Show dashboard button
                        if (dashboardBtn) {
                            dashboardBtn.classList.remove("hidden");
                        }
                        studentInfo.textContent = `Welcome, ${teacherData.summary.teacher.name} (Teacher)`;
                    }
                }
            } catch (e) {
                dbg("Teacher check failed", e);
            }

            if (currentRole !== "teacher") {
                currentRole = "student";
                teacherPanel.classList.add("hidden");
                if (dashboardBtn) {
                    dashboardBtn.classList.add("hidden");
                }
                studentInfo.textContent = `Welcome, ${dni} (Student)`;
            }
        } catch (e) {
            dbg("loadDashboard exception", e);
            showError("Error loading dashboard: " + e.message);
        }
    });

    // ---------- Start selected test ----------
    startSelectedBtn.addEventListener("click", async function () {
        errorDiv.textContent = "";
        const testId = testSelect.value;
        dbg("Start selected test clicked, testId=", testId);
        if (!testId) {
            showError("Select a test first.");
            return;
        }
        if (!currentDni) {
            showError("Load your dashboard first.");
            return;
        }

        // Redirect to quiz page with test_id
        // Quiz page will handle starting the test
        window.location.href = `/quiz?test_id=${testId}`;
    });

    // ---------- Create random test ----------
    createRandomBtn.addEventListener("click", async function () {
        randomInfo.textContent = "";
        const numQuestions = parseInt(numQuestionsInput.value, 10);
        const maxAttempts = maxAttemptsInput ? parseInt(maxAttemptsInput.value, 10) : null;
        
        dbg("Create random test clicked, numQuestions=", numQuestions, "maxAttempts=", maxAttempts);
        if (isNaN(numQuestions) || numQuestions < 1) {
            randomInfo.textContent = "Enter a valid number of questions (>=1).";
            return;
        }
        if (!currentDni) {
            randomInfo.textContent = "Load your dashboard first.";
            return;
        }

        try {
            const payload = {
                student_dni: currentDni,
                num_questions: numQuestions,
            };
            // Only include max_attempts if it's a valid positive number
            if (!isNaN(maxAttempts) && maxAttempts > 0) {
                payload.max_attempts = maxAttempts;
            }
            // If maxAttempts is 0 or empty, don't send it (NULL = unlimited)
            
            const resp = await fetch("/tests/random_from_bank", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(payload),
            });
            dbg("create random test response status", resp.status);
            if (!resp.ok) {
                const txt = await resp.text();
                dbg("create random test error body", txt);
                randomInfo.textContent = "Error creating test: " + txt;
                return;
            }
            const data = await resp.json();
            dbg("create random test response json", data);
            if (data.error) {
                randomInfo.textContent = data.error;
                return;
            }

            // Redirect to quiz page with test_id
            const testId = data.test_id;
            window.location.href = `/quiz?test_id=${testId}`;
        } catch (e) {
            dbg("createRandomTest exception", e);
            randomInfo.textContent = "Error creating test: " + e;
        }
    });

    // View podium
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
                `/tests/${encodeURIComponent(testId)}?teacher_dni=${encodeURIComponent(currentDni)}`,
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
            deleteTestInfo.textContent = data.message || "Test deleted successfully.";

            // Refresh tests list
            loadDashboardBtn.click();
        } catch (e) {
            dbg("delete_test exception", e);
            deleteTestInfo.textContent = "Error deleting test: " + e;
        }
    });

    // Teacher: rename test
    renameTestBtn.addEventListener("click", async function () {
        deleteTestInfo.textContent = "";
        dbg("Rename test button clicked, role=", currentRole);
        if (currentRole !== "teacher") {
            deleteTestInfo.textContent = "Only teachers can rename tests.";
            return;
        }
        const testId = testSelect.value;
        if (!testId) {
            deleteTestInfo.textContent = "Select a test first.";
            return;
        }

        const newTitle = prompt("Enter new title for this test:");
        if (!newTitle || !newTitle.trim()) {
            return; // Cancelled or empty
        }

        try {
            const resp = await fetch(`/tests/${encodeURIComponent(testId)}`, {
                method: "PUT",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    title: newTitle.trim(),
                    teacher_dni: currentDni
                }),
            });
            dbg("rename_test response status", resp.status);
            if (!resp.ok) {
                const txt = await resp.text();
                deleteTestInfo.textContent = "Error renaming test: " + txt;
                return;
            }
            const data = await resp.json();
            if (data.error) {
                deleteTestInfo.textContent = data.error;
                return;
            }
            deleteTestInfo.textContent = data.message || "Test renamed successfully.";

            // Refresh tests list
            loadDashboardBtn.click();
        } catch (e) {
            dbg("rename_test exception", e);
            deleteTestInfo.textContent = "Error renaming test: " + e;
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
