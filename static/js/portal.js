(function () {
    // ---------- Debug / verbose logging ----------
    // FORCE logging on for debugging
    console.log("[portal] Script starting...");
    
    const VERBOSE = true; // Force verbose for debugging
    
    function dbg(...args) {
        if (VERBOSE) {
            console.log("[portal]", ...args);
        }
    }

    dbg("portal.js loaded");

    // ---------- Theme handling (still in localStorage) ----------
    const themeToggle = document.getElementById("theme-toggle");
    if (themeToggle) {
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
    } else {
        console.error("[portal] theme-toggle element not found!");
    }

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

    // ---------- DOM references ----------
    const loginCard = document.getElementById("login-card");
    const dniInput = document.getElementById("student-dni");
    const loadDashboardBtn = document.getElementById("load-dashboard");
    const errorDiv = document.getElementById("error");
    const dashboard = document.getElementById("dashboard");
    const studentInfo = document.getElementById("student-info");
    const testSelect = document.getElementById("test-select");
    const startSelectedBtn = document.getElementById("start-selected-test");
    const testNameInput = document.getElementById("test-name");  // Custom test name
    const numQuestionsInput = document.getElementById("num-questions");
    const maxAttemptsInput = document.getElementById("max-attempts");  // Max attempts (teacher only)
    const maxAttemptsContainer = document.getElementById("max-attempts-container");
    const createRandomBtn = document.getElementById("create-random-test");
    const randomInfo = document.getElementById("random-info");
    const attemptsEmpty = document.getElementById("attempts-empty");
    const attemptsTableWrapper = document.getElementById("attempts-table-wrapper");
    const attemptsTableBody = document.getElementById("attempts-table-body");
    const attemptsChartCanvas = document.getElementById("attempts-chart");

    const viewPodiumBtn = document.getElementById("view-podium-btn");
    const podiumInfo = document.getElementById("podium-info");

    // Rename button for all users
    const renameMyTestBtn = document.getElementById("rename-my-test-btn");
    const renameInfo = document.getElementById("rename-info");

    const teacherPanel = document.getElementById("teacher-panel");
    const deleteTestBtn = document.getElementById("delete-test-btn");
    const renameTestBtn = document.getElementById("rename-test-btn");
    const deleteTestInfo = document.getElementById("delete-test-info");
    const loadAnalyticsBtn = document.getElementById("load-analytics-btn");
    const analyticsOutput = document.getElementById("analytics-output");

    // Debug: log which elements were found
    dbg("Elements found:", {
        loginCard: !!loginCard,
        dniInput: !!dniInput,
        loadDashboardBtn: !!loadDashboardBtn,
        errorDiv: !!errorDiv,
        dashboard: !!dashboard,
        homeBtn: !!homeBtn,
        logoutBtn: !!logoutBtn
    });

    let currentDni = null;
    let currentRole = null;
    let attemptsChart = null;
    let currentPage = 1;
    const attemptsPerPage = 5;
    let allAttempts = [];

    function showError(msg) {
        if (errorDiv) {
            errorDiv.textContent = msg;
        }
        dbg("ERROR:", msg);
    }

    // ---------- Navigation button handlers (with null checks) ----------
    if (homeBtn) {
        homeBtn.addEventListener("click", function () {
            dbg("Home button clicked");
            window.location.href = "/";
        });
    } else {
        console.warn("[portal] btn-home not found");
    }

    if (logoutBtn) {
        logoutBtn.addEventListener("click", function () {
            dbg("Logout button clicked");
            // Clear DNI cookie and reset dashboard
            deleteCookie("quiz_dni");
            currentDni = null;
            currentRole = null;
            if (dashboard) dashboard.classList.add("hidden");
            // Show login card again
            if (loginCard) {
                loginCard.classList.remove("hidden");
            }
            if (studentInfo) studentInfo.textContent = "";
            if (attemptsTableBody) attemptsTableBody.innerHTML = "";
            if (attemptsChart) {
                attemptsChart.destroy();
                attemptsChart = null;
            }
            if (dniInput) dniInput.value = "";
            if (errorDiv) errorDiv.textContent = "";
            if (randomInfo) randomInfo.textContent = "";
            if (podiumInfo) podiumInfo.textContent = "";
            if (deleteTestInfo) deleteTestInfo.textContent = "";
            if (analyticsOutput) analyticsOutput.textContent = "";
            if (teacherPanel) teacherPanel.classList.add("hidden");
            // Hide dashboard button
            if (dashboardBtn) {
                dashboardBtn.classList.add("hidden");
            }
            // Hide rename button
            if (renameMyTestBtn) {
                renameMyTestBtn.classList.add("hidden");
            }
            if (renameInfo) {
                renameInfo.textContent = "";
            }
            // Hide max attempts (teacher only)
            if (maxAttemptsContainer) {
                maxAttemptsContainer.classList.add("hidden");
            }
            if (maxAttemptsInput) {
                maxAttemptsInput.value = "";
            }
        });
    } else {
        console.warn("[portal] btn-logout not found");
    }

    // Dashboard button (teacher only)
    if (dashboardBtn) {
        dashboardBtn.addEventListener("click", function () {
            dbg("Dashboard button clicked");
            window.location.href = "/dashboard";
        });
        // Hide by default, will show when teacher logs in
        dashboardBtn.classList.add("hidden");
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
        if (!testSelect) return;
        
        testSelect.innerHTML = "";
        if (!tests || tests.length === 0) {
            const opt = document.createElement("option");
            opt.value = "";
            opt.textContent = "No tests available";
            testSelect.appendChild(opt);
            testSelect.disabled = true;
            if (startSelectedBtn) startSelectedBtn.disabled = true;
            if (viewPodiumBtn) viewPodiumBtn.disabled = true;
            return;
        }
        testSelect.disabled = false;
        if (startSelectedBtn) startSelectedBtn.disabled = false;
        if (viewPodiumBtn) viewPodiumBtn.disabled = false;

        tests.forEach((t) => {
            const opt = document.createElement("option");
            opt.value = String(t.id);
            // Show max attempts in label if set
            let label = `#${t.id} — ${t.title} (${t.num_questions} q)`;
            if (t.max_attempts) {
                label += ` [${t.max_attempts} attempts max]`;
            }
            opt.textContent = label;
            testSelect.appendChild(opt);
        });
    }

    function renderAttemptsTable(attempts) {
        dbg("renderAttemptsTable() with", attempts.length, "attempts");
        allAttempts = attempts;
        currentPage = 1;
        renderAttemptsPage();
    }

    function renderAttemptsPage() {
        if (!attemptsTableBody) return;
        attemptsTableBody.innerHTML = "";

        if (allAttempts.length === 0) {
            if (attemptsEmpty) attemptsEmpty.classList.remove("hidden");
            if (attemptsTableWrapper) attemptsTableWrapper.classList.add("hidden");
            hidePagination();
            return;
        }

        if (attemptsEmpty) attemptsEmpty.classList.add("hidden");
        if (attemptsTableWrapper) attemptsTableWrapper.classList.remove("hidden");

        const totalPages = Math.ceil(allAttempts.length / attemptsPerPage);
        const startIndex = (currentPage - 1) * attemptsPerPage;
        const endIndex = startIndex + attemptsPerPage;
        const pageAttempts = allAttempts.slice(startIndex, endIndex);

        pageAttempts.forEach((a) => {
            const row = document.createElement("tr");
            const score = a.score != null ? a.score.toFixed(2) : "-";
            const maxScore = a.max_score != null ? a.max_score.toFixed(2) : "-";
            const percentage = a.percentage != null ? a.percentage.toFixed(1) : "-";
            const submittedStr = a.submitted_at
                ? new Date(a.submitted_at).toLocaleString()
                : "-";

            row.innerHTML = `
                <td>${submittedStr}</td>
                <td>${a.test_title || "N/A"}</td>
                <td>${a.attempt_number}</td>
                <td>${score} / ${maxScore}</td>
                <td>${percentage}%</td>
                <td>${a.status || "-"}</td>
            `;
            attemptsTableBody.appendChild(row);
        });

        renderPagination(totalPages);
    }

    function renderPagination(totalPages) {
        let paginationDiv = document.getElementById("attempts-pagination");

        if (!paginationDiv && attemptsTableWrapper) {
            paginationDiv = document.createElement("div");
            paginationDiv.id = "attempts-pagination";
            paginationDiv.style.cssText = "margin-top: 0.5rem; display: flex; gap: 0.5rem; align-items: center; justify-content: center;";
            attemptsTableWrapper.after(paginationDiv);
        }

        if (!paginationDiv) return;

        if (totalPages <= 1) {
            paginationDiv.classList.add("hidden");
            return;
        }

        paginationDiv.classList.remove("hidden");
        paginationDiv.innerHTML = `
            <button id="prev-page" type="button" ${currentPage === 1 ? "disabled" : ""}>← Prev</button>
            <span>Page ${currentPage} of ${totalPages}</span>
            <button id="next-page" type="button" ${currentPage === totalPages ? "disabled" : ""}>Next →</button>
        `;

        document.getElementById("prev-page").addEventListener("click", () => {
            if (currentPage > 1) {
                currentPage--;
                renderAttemptsPage();
            }
        });

        document.getElementById("next-page").addEventListener("click", () => {
            if (currentPage < totalPages) {
                currentPage++;
                renderAttemptsPage();
            }
        });
    }

    function hidePagination() {
        const paginationDiv = document.getElementById("attempts-pagination");
        if (paginationDiv) {
            paginationDiv.classList.add("hidden");
        }
    }

    function renderAttemptsChart(attempts) {
        dbg("renderAttemptsChart() with", attempts.length, "attempts");
        if (attemptsChart) {
            attemptsChart.destroy();
            attemptsChart = null;
        }
        if (!attemptsChartCanvas || attempts.length === 0) {
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
                linesBest.push(`${i + 1}. ${s.name} — ${pct}%`);
            });
        }

        const linesAvg = ["<strong>📊 Best average:</strong>"];
        if (podAvg.length === 0) {
            linesAvg.push("(no data yet)");
        } else {
            podAvg.forEach((s, i) => {
                const pct =
                    s.avg_percentage != null ? s.avg_percentage.toFixed(1) : "-";
                linesAvg.push(`${i + 1}. ${s.name} — ${pct}%`);
            });
        }

        return linesBest.join("<br>") + "<br><br>" + linesAvg.join("<br>");
    }

    // ---------- Load dashboard for DNI ----------
    if (loadDashboardBtn) {
        loadDashboardBtn.addEventListener("click", async function () {
            dbg("Load dashboard button clicked");
            
            if (errorDiv) errorDiv.textContent = "";
            if (randomInfo) randomInfo.textContent = "";
            if (podiumInfo) podiumInfo.textContent = "";
            if (deleteTestInfo) deleteTestInfo.textContent = "";
            if (analyticsOutput) analyticsOutput.textContent = "";
            if (renameInfo) renameInfo.textContent = "";

            const dni = dniInput ? dniInput.value.trim() : "";
            dbg("DNI=", dni);
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
                    // Show login card on error
                    if (loginCard) {
                        loginCard.classList.remove("hidden");
                    }
                    return;
                }

                const attempts = attemptsData.attempts || [];

                // Filter out incomplete attempts and zero-score attempts
                const filteredAttempts = attempts.filter(a =>
                    a.status === 'graded' && a.score > 0
                );

                renderAttemptsTable(filteredAttempts);
                renderAttemptsChart(filteredAttempts);

                // Show dashboard, hide login card
                if (dashboard) dashboard.classList.remove("hidden");
                if (loginCard) loginCard.classList.add("hidden");

                // Show rename button for all logged-in users
                if (renameMyTestBtn) {
                    renameMyTestBtn.classList.remove("hidden");
                }

                // Check if teacher
                currentRole = null;
                try {
                    const teacherCheck = await fetch(
                        `/teacher/dashboard_overview?teacher_dni=${encodeURIComponent(dni)}`
                    );
                    if (teacherCheck.ok) {
                        const teacherData = await teacherCheck.json();
                        if (!teacherData.error) {
                            currentRole = "teacher";
                            if (teacherPanel) teacherPanel.classList.remove("hidden");
                            if (dashboardBtn) dashboardBtn.classList.remove("hidden");
                            if (studentInfo) studentInfo.textContent = `Welcome, ${teacherData.summary.teacher.name} (Teacher)`;
                            // Show max attempts input for teachers
                            if (maxAttemptsContainer) {
                                maxAttemptsContainer.classList.remove("hidden");
                            }
                        }
                    }
                } catch (e) {
                    dbg("Teacher check failed", e);
                }

                if (currentRole !== "teacher") {
                    currentRole = "student";
                    if (teacherPanel) teacherPanel.classList.add("hidden");
                    if (dashboardBtn) dashboardBtn.classList.add("hidden");
                    if (studentInfo) studentInfo.textContent = `Welcome, ${dni} (Student)`;
                    // Hide max attempts input for students
                    if (maxAttemptsContainer) {
                        maxAttemptsContainer.classList.add("hidden");
                    }
                }
            } catch (e) {
                dbg("loadDashboard exception", e);
                showError("Error loading dashboard: " + e.message);
            }
        });
    } else {
        console.error("[portal] load-dashboard button not found!");
    }

    // ---------- Start selected test ----------
    if (startSelectedBtn) {
        startSelectedBtn.addEventListener("click", async function () {
            if (errorDiv) errorDiv.textContent = "";
            const testId = testSelect ? testSelect.value : "";
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
            window.location.href = `/quiz?test_id=${testId}`;
        });
    }

    // ---------- Create random test ----------
    if (createRandomBtn) {
        createRandomBtn.addEventListener("click", async function () {
            if (randomInfo) randomInfo.textContent = "";
            const numQuestions = numQuestionsInput ? parseInt(numQuestionsInput.value, 10) : 0;
            const testName = testNameInput ? testNameInput.value.trim() : "";
            const maxAttempts = maxAttemptsInput ? parseInt(maxAttemptsInput.value, 10) : NaN;
            
            dbg("Create random test clicked, numQuestions=", numQuestions, "testName=", testName, "maxAttempts=", maxAttempts);
            
            if (isNaN(numQuestions) || numQuestions < 1) {
                if (randomInfo) randomInfo.textContent = "Enter a valid number of questions (>=1).";
                return;
            }
            if (!currentDni) {
                if (randomInfo) randomInfo.textContent = "Load your dashboard first.";
                return;
            }

            try {
                const payload = {
                    student_dni: currentDni,
                    num_questions: numQuestions,
                };
                
                // Add title only if provided
                if (testName) {
                    payload.title = testName;
                }
                
                // Add max_attempts only if provided and valid (teacher only feature, backend will validate)
                if (!isNaN(maxAttempts) && maxAttempts >= 1) {
                    payload.max_attempts = maxAttempts;
                }
                
                const resp = await fetch("/tests/random_from_bank", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify(payload),
                });
                dbg("create random test response status", resp.status);
                if (!resp.ok) {
                    const txt = await resp.text();
                    dbg("create random test error body", txt);
                    if (randomInfo) randomInfo.textContent = "Error creating test: " + txt;
                    return;
                }
                const data = await resp.json();
                dbg("create random test response json", data);
                if (data.error) {
                    if (randomInfo) randomInfo.textContent = data.error;
                    return;
                }

                // Redirect to quiz page with test_id
                const testId = data.test_id;
                window.location.href = `/quiz?test_id=${testId}`;
            } catch (e) {
                dbg("createRandomTest exception", e);
                if (randomInfo) randomInfo.textContent = "Error creating test: " + e;
            }
        });
    }

    // View podium
    if (viewPodiumBtn) {
        viewPodiumBtn.addEventListener("click", async function () {
            if (podiumInfo) podiumInfo.textContent = "";
            const testId = testSelect ? testSelect.value : "";
            dbg("View podium clicked, testId=", testId);
            if (!testId) {
                showError("Select a test first.");
                return;
            }
            try {
                const data = await fetchAnalytics(testId);
                if (data.error) {
                    if (podiumInfo) podiumInfo.textContent = data.error;
                    return;
                }
                if (!data.analytics) {
                    if (podiumInfo) podiumInfo.textContent = "No analytics available yet.";
                    return;
                }
                const html = [
                    `<strong>Test:</strong> #${data.test.id} — ${data.test.title}`,
                    "<br>",
                    formatPodiumHtml(data.analytics),
                ].join("<br>");
                if (podiumInfo) podiumInfo.innerHTML = html;
            } catch (e) {
                dbg("viewPodium exception", e);
                if (podiumInfo) podiumInfo.textContent = "Error loading podium: " + e;
            }
        });
    }

    // ---------- Rename test (for all users - can rename their own tests) ----------
    if (renameMyTestBtn) {
        renameMyTestBtn.addEventListener("click", async function () {
            if (renameInfo) renameInfo.textContent = "";
            
            const testId = testSelect ? testSelect.value : "";
            dbg("Rename my test clicked, testId=", testId);
            
            if (!testId) {
                if (renameInfo) renameInfo.textContent = "Select a test first.";
                return;
            }
            if (!currentDni) {
                if (renameInfo) renameInfo.textContent = "Load your dashboard first.";
                return;
            }

            const newTitle = prompt("Enter new name for this test:");
            if (!newTitle || !newTitle.trim()) {
                return; // Cancelled or empty
            }

            try {
                const resp = await fetch(`/tests/${encodeURIComponent(testId)}`, {
                    method: "PUT",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        title: newTitle.trim(),
                        user_dni: currentDni
                    }),
                });
                dbg("rename_test response status", resp.status);
                if (!resp.ok) {
                    const txt = await resp.text();
                    if (renameInfo) renameInfo.textContent = "Error: " + txt;
                    return;
                }
                const data = await resp.json();
                if (data.error) {
                    if (renameInfo) renameInfo.textContent = data.error;
                    return;
                }
                if (renameInfo) renameInfo.textContent = data.message || "Test renamed!";

                // Refresh tests list
                if (loadDashboardBtn) loadDashboardBtn.click();
            } catch (e) {
                dbg("rename_test exception", e);
                if (renameInfo) renameInfo.textContent = "Error: " + e;
            }
        });
    }

    // Teacher: delete test
    if (deleteTestBtn) {
        deleteTestBtn.addEventListener("click", async function () {
            if (deleteTestInfo) deleteTestInfo.textContent = "";
            dbg("Delete test button clicked, role=", currentRole);
            if (currentRole !== "teacher") {
                if (deleteTestInfo) deleteTestInfo.textContent =
                    "Only teachers can delete tests (role=teacher).";
                return;
            }
            const testId = testSelect ? testSelect.value : "";
            if (!testId) {
                if (deleteTestInfo) deleteTestInfo.textContent = "Select a test first.";
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
                    if (deleteTestInfo) deleteTestInfo.textContent = "Error deleting test: " + txt;
                    return;
                }
                const data = await resp.json();
                dbg("delete_test response json", data);
                if (data.error) {
                    if (deleteTestInfo) deleteTestInfo.textContent = data.error;
                    return;
                }
                if (deleteTestInfo) deleteTestInfo.textContent = data.message || "Test deleted successfully.";

                // Refresh tests list
                if (loadDashboardBtn) loadDashboardBtn.click();
            } catch (e) {
                dbg("delete_test exception", e);
                if (deleteTestInfo) deleteTestInfo.textContent = "Error deleting test: " + e;
            }
        });
    }

    // Teacher: rename test (in teacher panel - can rename ANY test)
    if (renameTestBtn) {
        renameTestBtn.addEventListener("click", async function () {
            if (deleteTestInfo) deleteTestInfo.textContent = "";
            dbg("Rename test button clicked (teacher panel), role=", currentRole);
            if (currentRole !== "teacher") {
                if (deleteTestInfo) deleteTestInfo.textContent = "Only teachers can use this panel.";
                return;
            }
            const testId = testSelect ? testSelect.value : "";
            if (!testId) {
                if (deleteTestInfo) deleteTestInfo.textContent = "Select a test first.";
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
                    if (deleteTestInfo) deleteTestInfo.textContent = "Error renaming test: " + txt;
                    return;
                }
                const data = await resp.json();
                if (data.error) {
                    if (deleteTestInfo) deleteTestInfo.textContent = data.error;
                    return;
                }
                if (deleteTestInfo) deleteTestInfo.textContent = data.message || "Test renamed successfully.";

                // Refresh tests list
                if (loadDashboardBtn) loadDashboardBtn.click();
            } catch (e) {
                dbg("rename_test exception", e);
                if (deleteTestInfo) deleteTestInfo.textContent = "Error renaming test: " + e;
            }
        });
    }

    // Teacher: load analytics
    if (loadAnalyticsBtn) {
        loadAnalyticsBtn.addEventListener("click", async function () {
            if (analyticsOutput) analyticsOutput.textContent = "";
            const testId = testSelect ? testSelect.value : "";
            dbg("Load analytics clicked, testId=", testId);
            if (!testId) {
                if (analyticsOutput) analyticsOutput.textContent = "Select a test first.";
                return;
            }
            try {
                const data = await fetchAnalytics(testId);
                if (data.error) {
                    if (analyticsOutput) analyticsOutput.textContent = data.error;
                    return;
                }
                const a = data.analytics;
                if (!a) {
                    if (analyticsOutput) analyticsOutput.textContent = "No analytics available yet.";
                    return;
                }

                const lines = [];
                lines.push(
                    `<strong>Test:</strong> #${data.test.id} — ${data.test.title}`
                );
                lines.push("<br>");

                // Questions
                if (a.most_failed_question) {
                    const q = a.most_failed_question;
                    const wr = q.wrong_rate != null ? (q.wrong_rate * 100).toFixed(1) : "-";
                    lines.push(
                        `<strong>Most failed question:</strong> [Q${q.question_id}] ` +
                        `${q.text} (wrong: ${q.wrong_count} / ${q.total_answers}, ${wr}%)`
                    );
                } else {
                    lines.push("<strong>Most failed question:</strong> no data yet.");
                }

                if (a.most_correct_question) {
                    const q = a.most_correct_question;
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
                        `— wrong: ${o.wrong_selected} / ${o.times_selected}, ${wr}%`
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
                        `— correct: ${o.correct_selected} / ${o.times_selected}, ${cr}%`
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

                if (analyticsOutput) analyticsOutput.innerHTML = lines.join("<br>");
            } catch (e) {
                dbg("loadAnalytics exception", e);
                if (analyticsOutput) analyticsOutput.textContent = "Error loading analytics: " + e;
            }
        });
    }

    // ---------- On load: auto-login if cookie exists ----------
    dbg("Checking for existing DNI cookie...");
    const cookieDni = getCookie("quiz_dni");
    if (cookieDni) {
        dbg("Found DNI cookie, auto-loading dashboard:", cookieDni);
        if (dniInput) dniInput.value = cookieDni;
        // Hide login card and auto-load dashboard
        if (loginCard) {
            loginCard.classList.add("hidden");
        }
        // Trigger dashboard load
        if (loadDashboardBtn) {
            loadDashboardBtn.click();
        }
    } else {
        dbg("No quiz_dni cookie found, showing login card");
        // Login card is visible by default
    }
    
    console.log("[portal] Script finished initialization");
})();
