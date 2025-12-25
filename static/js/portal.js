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
        // Show login card again
        const loginCard = document.getElementById("login-card");
        if (loginCard) {
            loginCard.classList.remove("hidden");
        }
        studentInfo.textContent = "";
        attemptsTableBody.innerHTML = "";
        if (attemptsChart) {
            attemptsChart.destroy();
            attemptsChart = null;
        }
        dniInput.value = "";
        errorDiv.textContent = "";
        errorDiv.classList.add("hidden");
        randomInfo.textContent = "";
        podiumInfo.textContent = "";
        deleteTestInfo.textContent = "";
        analyticsOutput.textContent = "";
        teacherPanel.classList.add("hidden");
        // Hide dashboard button
        if (dashboardBtn) {
            dashboardBtn.classList.add("hidden");
        }
        // Clear rename info
        if (renameInfo) {
            renameInfo.textContent = "";
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
    const loginCard = document.getElementById("login-card");
    const dniInput = document.getElementById("student-dni");
    const loadDashboardBtn = document.getElementById("load-dashboard");
    const errorDiv = document.getElementById("error");
    const dashboard = document.getElementById("dashboard");
    const studentInfo = document.getElementById("student-info");
    const courseSelect = document.getElementById("course-select");
    const testSelect = document.getElementById("test-select");
    const startSelectedBtn = document.getElementById("start-selected-test");
    const testNameInput = document.getElementById("test-name");
    const numQuestionsInput = document.getElementById("num-questions");
    const maxAttemptsInput = document.getElementById("max-attempts");
    const timeLimitInput = document.getElementById("time-limit");
    const testTypeSelect = document.getElementById("test-type");
    const createRandomBtn = document.getElementById("create-random-test");
    const randomInfo = document.getElementById("random-info");
    const attemptsEmpty = document.getElementById("attempts-empty");
    const attemptsTableWrapper = document.getElementById("attempts-table-wrapper");
    const attemptsTableBody = document.getElementById("attempts-table-body");
    const attemptsChartCanvas = document.getElementById("attempts-chart");

    const viewPodiumBtn = document.getElementById("view-podium-btn");
    const podiumInfo = document.getElementById("podium-info");
    const shareTestBtn = document.getElementById("share-test-btn");

    // Rename button for all users (to rename their own tests)
    const renameInfo = document.getElementById("rename-info");

    const teacherPanel = document.getElementById("teacher-panel");
    const deleteTestBtn = document.getElementById("delete-test-btn");
    const renameTestBtn = document.getElementById("rename-test-btn");
    const deleteTestInfo = document.getElementById("delete-test-info");
    const loadAnalyticsBtn = document.getElementById("load-analytics-btn");
    const analyticsOutput = document.getElementById("analytics-output");
    const btnQuestionBank = document.getElementById("btn-question-bank");
    const manageUsersBtn = document.getElementById("manage-users-btn");
    const usersManagement = document.getElementById("users-management");
    const usersList = document.getElementById("users-list");

    // Power Student Panel
    const powerStudentPanel = document.getElementById("power-student-panel");
    const btnBrowseQuestions = document.getElementById("btn-browse-questions");
    const btnSuggestQuestion = document.getElementById("btn-suggest-question");
    const suggestQuestionForm = document.getElementById("suggest-question-form");
    const suggestQuestionText = document.getElementById("suggest-question-text");
    const suggestOptions = [
        document.getElementById("suggest-option-0"),
        document.getElementById("suggest-option-1"),
        document.getElementById("suggest-option-2"),
        document.getElementById("suggest-option-3"),
    ];
    const btnSubmitSuggestion = document.getElementById("btn-submit-suggestion");
    const btnCancelSuggestion = document.getElementById("btn-cancel-suggestion");
    const suggestionResult = document.getElementById("suggestion-result");

    // Weak Questions
    const btnShowWeakQuestions = document.getElementById("btn-show-weak-questions");
    const weakQuestionsSection = document.getElementById("weak-questions-section");
    const weakQuestionsList = document.getElementById("weak-questions-list");

    let currentDni = null;
    let currentRole = null;
    let attemptsChart = null;
    let selectedCourseId = null;
    let selectedCourse = null;
    let allCourses = [];
    let allTests = [];
    let allAttempts = [];

    function showError(msg) {
        console.log("[DEBUG] showError called with:", msg);
        console.log("[DEBUG] errorDiv element:", errorDiv);
        if (errorDiv) {
            errorDiv.textContent = msg;
            errorDiv.classList.remove('hidden');
            console.log("[DEBUG] Error message set successfully");
        } else {
            console.error("[DEBUG] errorDiv not found!");
        }
        dbg("ERROR:", msg);
    }

    // ---------- API helpers ----------
    async function fetchCourses() {
        dbg("fetchCourses() start");
        const resp = await fetch("/courses");
        dbg("fetchCourses() status", resp.status);
        if (!resp.ok) {
            const txt = await resp.text();
            dbg("fetchCourses() error body:", txt);
            throw new Error("Error fetching courses: " + txt);
        }
        const data = await resp.json();
        dbg("fetchCourses() data:", data);
        return data;
    }

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
    function populateCoursesSelect(courses) {
        dbg("populateCoursesSelect() with", courses ? courses.length : 0, "courses");
        courseSelect.innerHTML = '<option value="">-- Select Course --</option>';
        if (!courses || courses.length === 0) {
            courseSelect.disabled = true;
            return;
        }
        courseSelect.disabled = false;
        courses.forEach((c) => {
            const opt = document.createElement("option");
            opt.value = String(c.id);
            opt.textContent = `${c.code} - ${c.name}`;
            courseSelect.appendChild(opt);
        });
    }

    function filterAndPopulateTests() {
        dbg("filterAndPopulateTests() for course", selectedCourseId);

        // Only show tests when a course is selected
        if (!selectedCourseId) {
            populateTestsSelect([]);
            return;
        }

        const filteredTests = allTests.filter(t => t.course_id === selectedCourseId);
        populateTestsSelect(filteredTests);
    }

    function filterAndRenderAttempts() {
        dbg("filterAndRenderAttempts() for course", selectedCourseId);

        // Filter to only graded attempts
        const gradedAttempts = allAttempts.filter(a => a.status === 'graded');

        // If a course is selected, filter by course
        let filteredAttempts = gradedAttempts;
        if (selectedCourseId) {
            // Filter attempts by matching test_id with tests from selected course
            const courseTestIds = new Set(
                allTests.filter(t => t.course_id === selectedCourseId).map(t => t.id)
            );
            filteredAttempts = gradedAttempts.filter(a => courseTestIds.has(a.test_id));
        }

        renderAttemptsTable(filteredAttempts);
        renderAttemptsChart(filteredAttempts);
    }

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

            // Build actions column - compact icon buttons
            let actionsHtml = '<div style="display: flex; gap: 0.25rem; justify-content: center;">';

            // Study mode button for failed attempts (percentage < 70%)
            if (a.status === "graded" && a.percentage != null && a.percentage < 70) {
                actionsHtml += `<button class="study-mode-btn" data-attempt-id="${a.attempt_id}" data-test-title="${a.test_title || 'N/A'}" title="Study Mode" style="padding: 0.3rem 0.6rem; font-size: 1.2rem; min-width: unset;">📚</button>`;
            }

            // Delete button for tests created by student
            if (a.can_delete) {
                actionsHtml += `<button class="delete-test-btn" data-test-id="${a.test_id}" data-test-title="${a.test_title || 'N/A'}" title="Delete Test" style="padding: 0.3rem 0.6rem; font-size: 1.2rem; min-width: unset;">🗑️</button>`;
            }

            actionsHtml += '</div>';

            row.innerHTML = `
                <td>${submittedStr}</td>
                <td>${a.test_title || "N/A"}</td>
                <td>${a.attempt_number}</td>
                <td>${score} / ${maxScore}</td>
                <td>${percentage}%</td>
                <td>${a.status || "-"}</td>
                <td>${actionsHtml}</td>
            `;
            attemptsTableBody.appendChild(row);
        });

        // Add event listeners for action buttons
        document.querySelectorAll(".study-mode-btn").forEach(btn => {
            btn.addEventListener("click", handleStudyMode);
        });

        document.querySelectorAll(".delete-test-btn").forEach(btn => {
            btn.addEventListener("click", handleDeleteTest);
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
        errorDiv.classList.add("hidden");
        randomInfo.textContent = "";
        podiumInfo.textContent = "";
        deleteTestInfo.textContent = "";
        analyticsOutput.textContent = "";
        if (renameInfo) renameInfo.textContent = "";

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

            // Fetch courses
            const coursesData = await fetchCourses();
            allCourses = coursesData.courses || [];
            populateCoursesSelect(allCourses);

            // Fetch tests
            const testsData = await fetchAvailableTests();
            allTests = testsData.tests || [];

            filterAndPopulateTests();

            // Fetch attempts
            const attemptsData = await fetchStudentAttempts(dni);
            console.log("[DEBUG] attemptsData:", attemptsData);
            if (attemptsData.error) {
                console.log("[DEBUG] Error detected:", attemptsData.error);
                // Check if it's a "user not found" error
                if (attemptsData.error.includes("not found")) {
                    console.log("[DEBUG] User not found error detected, showing comprehensive message");
                    showError(
                        `⚠️ User not found with DNI: ${dni}\n\n` +
                        `This DNI is not registered in the system.\n\n` +
                        `Possible reasons:\n` +
                        `• You may have entered the wrong DNI (check for typos)\n` +
                        `• Your account might not be created yet\n` +
                        `• You may need to contact your teacher or administrator\n\n` +
                        `Please verify your DNI and try again, or contact support for assistance.`
                    );
                } else {
                    console.log("[DEBUG] Generic error, showing:", attemptsData.error);
                    showError(attemptsData.error);
                }
                return;
            }

            allAttempts = attemptsData.attempts || [];

            filterAndRenderAttempts();

            // Check role from first attempt (if any)
            currentRole = null;
            if (allAttempts.length > 0) {
                // We don't have role in attempts, need to get from user
                // For now, check if DNI matches teacher pattern
                // Better: fetch user info from a /user/{dni} endpoint
            }

            // Show dashboard, hide login card
            dashboard.classList.remove("hidden");
            if (loginCard) {
                loginCard.classList.add("hidden");
            }


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
                currentRole = attemptsData.student?.role || "student";
                teacherPanel.classList.add("hidden");
                if (dashboardBtn) {
                    dashboardBtn.classList.add("hidden");
                }

                // Show power student panel if user is power_student
                if (currentRole === "power_student" && powerStudentPanel) {
                    powerStudentPanel.classList.remove("hidden");
                }

                // Show full name and specific role
                const userName = attemptsData.student?.name || dni;
                const roleDisplay = currentRole === "power_student" ? "Power Student" :
                                   currentRole.charAt(0).toUpperCase() + currentRole.slice(1);
                studentInfo.textContent = `Welcome, ${userName} (${roleDisplay})`;
            }
        } catch (e) {
            dbg("loadDashboard exception", e);
            showError("Error loading dashboard: " + e.message);
        }
    });

    // ---------- Course select change ----------
    courseSelect.addEventListener("change", function () {
        const value = courseSelect.value;
        selectedCourseId = value ? parseInt(value, 10) : null;
        selectedCourse = selectedCourseId ? allCourses.find(c => c.id === selectedCourseId) : null;
        dbg("Course selected:", selectedCourseId, selectedCourse);
        filterAndPopulateTests();
        filterAndRenderAttempts();
    });

    // ---------- Start selected test ----------
    startSelectedBtn.addEventListener("click", async function () {
        errorDiv.textContent = "";
        errorDiv.classList.add("hidden");
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
        const testName = testNameInput ? testNameInput.value.trim() : "";
        const maxAttempts = maxAttemptsInput ? parseInt(maxAttemptsInput.value, 10) : null;
        const timeLimit = timeLimitInput ? parseInt(timeLimitInput.value, 10) : null;
        const testType = testTypeSelect ? testTypeSelect.value : "quiz";
        const randomizeQuestions = true;  // Always randomize questions
        const randomizeOptions = true;    // Always randomize options

        dbg("Create random test clicked, numQuestions=", numQuestions, "testName=", testName, "maxAttempts=", maxAttempts,
            "timeLimit=", timeLimit, "testType=", testType, "randomizeQ=", randomizeQuestions, "randomizeO=", randomizeOptions);
        if (isNaN(numQuestions) || numQuestions < 1) {
            randomInfo.textContent = "Enter a valid number of questions (>=1).";
            return;
        }
        if (!currentDni) {
            randomInfo.textContent = "Load your dashboard first.";
            return;
        }
        if (!selectedCourse) {
            randomInfo.textContent = "Select a course first.";
            return;
        }

        try {
            const payload = {
                student_dni: currentDni,
                course_code: selectedCourse.code,
                num_questions: numQuestions,
                test_type: testType,
                randomize_questions: randomizeQuestions,
                randomize_options: randomizeOptions,
            };
            // Add title only if provided
            if (testName) {
                payload.title = testName;
            }
            // Only include max_attempts if it's a valid positive number
            if (!isNaN(maxAttempts) && maxAttempts > 0) {
                payload.max_attempts = maxAttempts;
            }
            // Only include time_limit if it's a valid positive number
            if (!isNaN(timeLimit) && timeLimit > 0) {
                payload.time_limit_minutes = timeLimit;
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

    // Share test
    shareTestBtn.addEventListener("click", async function () {
        const testId = testSelect.value;
        dbg("Share test clicked, testId=", testId);
        if (!testId) {
            alert("Please select a test first.");
            return;
        }

        const shareUrl = `${window.location.origin}/quiz?test_id=${testId}`;

        try {
            await navigator.clipboard.writeText(shareUrl);
            shareTestBtn.textContent = "✅ Link Copied!";
            setTimeout(() => {
                shareTestBtn.textContent = "🔗 Copy Share Link";
            }, 2000);
        } catch (err) {
            console.error("Failed to copy:", err);
            prompt("Copy this link to share:", shareUrl);
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


    // Teacher: open question bank
    if (btnQuestionBank) {
        btnQuestionBank.addEventListener("click", function () {
            dbg("Question bank button clicked");
            window.location.href = "/question-bank";
        });
    }

    // Power Student: browse questions (read-only)
    if (btnBrowseQuestions) {
        btnBrowseQuestions.addEventListener("click", function () {
            dbg("Browse questions button clicked");
            window.location.href = "/question-bank";
        });
    }

    // Suggest question - show form
    if (btnSuggestQuestion) {
        btnSuggestQuestion.addEventListener("click", function () {
            dbg("Suggest question button clicked");
            suggestQuestionForm.classList.toggle("hidden");
            if (!suggestQuestionForm.classList.contains("hidden")) {
                suggestQuestionText.focus();
            }
        });
    }

    // Cancel suggestion
    if (btnCancelSuggestion) {
        btnCancelSuggestion.addEventListener("click", function () {
            suggestQuestionForm.classList.add("hidden");
            suggestQuestionText.value = "";
            suggestOptions.forEach(opt => opt.value = "");
            suggestionResult.textContent = "";
        });
    }

    // Submit suggestion
    if (btnSubmitSuggestion) {
        btnSubmitSuggestion.addEventListener("click", async function () {
            dbg("Submit suggestion button clicked");

            const questionText = suggestQuestionText.value.trim();
            const options = suggestOptions.map(opt => opt.value.trim());
            const correctIdx = parseInt(document.querySelector('input[name="suggest-correct"]:checked').value);

            // Validation
            if (!questionText) {
                suggestionResult.textContent = "Please enter a question.";
                suggestionResult.style.color = "var(--error)";
                return;
            }

            if (options.some(opt => !opt)) {
                suggestionResult.textContent = "Please fill in all options.";
                suggestionResult.style.color = "var(--error)";
                return;
            }

            if (!currentDni || !selectedCourseId) {
                suggestionResult.textContent = "Please select a course first.";
                suggestionResult.style.color = "var(--error)";
                return;
            }

            try {
                btnSubmitSuggestion.disabled = true;
                btnSubmitSuggestion.textContent = "Submitting...";

                const response = await fetch("/api/question-suggestions", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        student_dni: currentDni,
                        course_id: selectedCourseId,
                        question_text: questionText,
                        options: options.map((text, idx) => ({
                            text,
                            is_correct: idx === correctIdx
                        }))
                    })
                });

                const data = await response.json();

                if (data.error) {
                    suggestionResult.textContent = data.error;
                    suggestionResult.style.color = "var(--error)";
                } else {
                    suggestionResult.textContent = "✅ " + (data.message || "Suggestion submitted successfully!");
                    suggestionResult.style.color = "green";

                    // Clear form after successful submission
                    setTimeout(() => {
                        suggestQuestionText.value = "";
                        suggestOptions.forEach(opt => opt.value = "");
                        suggestionResult.textContent = "";
                        suggestQuestionForm.classList.add("hidden");
                    }, 2000);
                }
            } catch (error) {
                console.error("Error submitting suggestion:", error);
                suggestionResult.textContent = "Failed to submit suggestion";
                suggestionResult.style.color = "var(--error)";
            } finally {
                btnSubmitSuggestion.disabled = false;
                btnSubmitSuggestion.textContent = "📤 Submit Suggestion";
            }
        });
    }

    // Show weak questions
    if (btnShowWeakQuestions) {
        btnShowWeakQuestions.addEventListener("click", async function () {
            dbg("Show weak questions button clicked");

            if (!currentDni) {
                weakQuestionsList.innerHTML = "<p>Please load your dashboard first.</p>";
                return;
            }

            try {
                btnShowWeakQuestions.disabled = true;
                btnShowWeakQuestions.textContent = "Loading...";

                const url = selectedCourseId
                    ? `/student/${encodeURIComponent(currentDni)}/weak_questions?course_id=${selectedCourseId}`
                    : `/student/${encodeURIComponent(currentDni)}/weak_questions`;

                const response = await fetch(url);
                const data = await response.json();

                if (data.error) {
                    weakQuestionsList.innerHTML = `<p style="color: var(--error);">${data.error}</p>`;
                    return;
                }

                const questions = data.weak_questions || [];

                if (questions.length === 0) {
                    weakQuestionsList.innerHTML = "<p style='color: var(--text-muted);'>No weak topics found - great job!</p>";
                } else {
                    let html = '<div style="max-height: 400px; overflow-y: auto;">';
                    html += '<table style="width: 100%; border-collapse: collapse;">';
                    html += '<thead><tr><th style="text-align: left;">Question</th><th>Times Wrong</th><th>Success Rate</th></tr></thead>';
                    html += '<tbody>';

                    questions.forEach(q => {
                        const successColor = q.success_rate < 30 ? 'var(--error)' : (q.success_rate < 70 ? 'orange' : 'green');
                        html += '<tr>';
                        html += `<td style="padding: 0.5rem;">${q.question_text.substring(0, 100)}${q.question_text.length > 100 ? '...' : ''}</td>`;
                        html += `<td style="text-align: center; padding: 0.5rem;">${q.times_wrong}</td>`;
                        html += `<td style="text-align: center; padding: 0.5rem; color: ${successColor};">${q.success_rate}%</td>`;
                        html += '</tr>';
                    });

                    html += '</tbody></table></div>';
                    weakQuestionsList.innerHTML = html;
                }

                weakQuestionsSection.classList.remove("hidden");
                btnShowWeakQuestions.textContent = "🔄 Refresh Weak Topics";
            } catch (error) {
                console.error("Error loading weak questions:", error);
                weakQuestionsList.innerHTML = `<p style="color: var(--error);">Failed to load weak topics</p>`;
            } finally {
                btnShowWeakQuestions.disabled = false;
            }
        });
    }

    // Teacher: manage users
    if (manageUsersBtn) {
        manageUsersBtn.addEventListener("click", async function () {
            dbg("Manage users button clicked");

            // Toggle visibility
            if (usersManagement.style.display === "none") {
                usersManagement.style.display = "block";
                await loadUsers();
            } else {
                usersManagement.style.display = "none";
            }
        });
    }

    async function loadUsers() {
        if (!currentDni) return;

        try {
            const response = await fetch(`/users?teacher_dni=${encodeURIComponent(currentDni)}`);
            const data = await response.json();

            if (data.error) {
                usersList.innerHTML = `<p style="color: var(--error);">${data.error}</p>`;
                return;
            }

            // Build bulk update controls
            let html = '<div style="margin-bottom: 1rem; padding: 1rem; background: var(--card-bg); border: 1px solid var(--border-color); border-radius: 4px;">';
            html += '<label>Change selected users to: </label>';
            html += '<select id="bulk-role-select" style="margin: 0 0.5rem;">';
            html += '<option value="">-- Select Role --</option>';
            html += '<option value="student">Student</option>';
            html += '<option value="power_student">Power Student</option>';
            html += '<option value="teacher">Teacher</option>';
            html += '<option value="admin">Admin</option>';
            html += '</select>';
            html += '<button id="bulk-update-btn" style="margin-left: 0.5rem;">Update Selected</button>';
            html += '</div>';

            // Build users table with checkboxes
            html += '<table style="width: 100%; border-collapse: collapse;"><thead><tr>';
            html += '<th><input type="checkbox" id="select-all-users" title="Select All"></th>';
            html += '<th>Name</th><th>Role</th><th>DNI</th><th>Email</th>';
            html += '</tr></thead><tbody>';

            data.users.forEach(user => {
                const roleDisplay = user.role === 'power_student' ? 'Power Student' :
                                   user.role.charAt(0).toUpperCase() + user.role.slice(1);
                html += '<tr>';
                html += `<td><input type="checkbox" class="user-checkbox" data-user-id="${user.id}" data-current-role="${user.role}"></td>`;
                html += `<td>${user.full_name}</td>`;
                html += `<td>${roleDisplay}</td>`;
                html += `<td>${user.dni}</td>`;
                html += `<td>${user.email}</td>`;
                html += '</tr>';
            });

            html += '</tbody></table>';
            usersList.innerHTML = html;

            // Add event listeners
            document.getElementById("select-all-users").addEventListener("change", function(e) {
                document.querySelectorAll(".user-checkbox").forEach(cb => {
                    cb.checked = e.target.checked;
                });
            });

            document.getElementById("bulk-update-btn").addEventListener("click", handleBulkUpdateRole);
        } catch (error) {
            console.error("Load users error:", error);
            usersList.innerHTML = `<p style="color: var(--error);">Failed to load users</p>`;
        }
    }

    async function handleBulkUpdateRole() {
        const newRole = document.getElementById("bulk-role-select").value;

        if (!newRole) {
            alert("Please select a role first");
            return;
        }

        // Get all checked users
        const checkedUsers = Array.from(document.querySelectorAll(".user-checkbox:checked"));

        if (checkedUsers.length === 0) {
            alert("Please select at least one user");
            return;
        }

        const count = checkedUsers.length;
        const roleDisplay = newRole === 'power_student' ? 'Power Student' :
                           newRole.charAt(0).toUpperCase() + newRole.slice(1);

        if (!confirm(`Change ${count} user(s) to ${roleDisplay}?`)) {
            return;
        }

        let successCount = 0;
        let errorCount = 0;

        for (const checkbox of checkedUsers) {
            const userId = checkbox.dataset.userId;
            const oldRole = checkbox.dataset.currentRole;

            if (newRole === oldRole) {
                continue; // Skip if role hasn't changed
            }

            try {
                const response = await fetch(`/users/${userId}/role?teacher_dni=${encodeURIComponent(currentDni)}&new_role=${encodeURIComponent(newRole)}`, {
                    method: "PUT"
                });
                const data = await response.json();

                if (data.error) {
                    console.error(`Failed to update user ${userId}:`, data.error);
                    errorCount++;
                } else {
                    successCount++;
                }
            } catch (error) {
                console.error(`Error updating user ${userId}:`, error);
                errorCount++;
            }
        }

        if (errorCount > 0) {
            alert(`Updated ${successCount} user(s), ${errorCount} failed. See console for details.`);
        } else {
            alert(`Successfully updated ${successCount} user(s) to ${roleDisplay}`);
        }

        // Reload the user list
        await loadUsers();
    }

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
                `/tests/${encodeURIComponent(testId)}?dni=${encodeURIComponent(currentDni)}`,
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

    // Rename test (for all users)
    renameTestBtn.addEventListener("click", async function () {
        if (renameInfo) renameInfo.textContent = "";

        const testId = testSelect.value;
        dbg("Rename test clicked, testId=", testId);

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
            loadDashboardBtn.click();
        } catch (e) {
            dbg("rename_test exception", e);
            if (renameInfo) renameInfo.textContent = "Error: " + e;
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

    // ---------- Study Mode Handler ----------
    async function handleStudyMode(e) {
        const attemptId = e.target.dataset.attemptId;
        const testTitle = e.target.dataset.testTitle;
        const dni = getCookie("quiz_dni");

        if (!confirm(`Create a study test with questions you got wrong from "${testTitle}"?`)) {
            return;
        }

        try {
            const response = await fetch(`/attempts/${attemptId}/study_mode?dni=${encodeURIComponent(dni)}`, {
                method: "POST"
            });
            const data = await response.json();

            if (data.error) {
                alert("Error creating study mode: " + data.error);
            } else {
                alert(`Study mode test created: "${data.title}" with ${data.num_questions} questions.\nStarting now!`);
                window.location.href = `/quiz?test_id=${data.test_id}&dni=${encodeURIComponent(dni)}`;
            }
        } catch (error) {
            console.error("Study mode error:", error);
            alert("Failed to create study mode test");
        }
    }

    // ---------- Delete Test Handler ----------
    async function handleDeleteTest(e) {
        const testId = e.target.dataset.testId;
        const testTitle = e.target.dataset.testTitle;
        const dni = getCookie("quiz_dni");

        if (!confirm(`Are you sure you want to delete "${testTitle}"?\nThis will also delete all attempts and results!`)) {
            return;
        }

        try {
            const response = await fetch(`/tests/${testId}?dni=${encodeURIComponent(dni)}`, {
                method: "DELETE"
            });
            const data = await response.json();

            if (data.error) {
                alert("Error deleting test: " + data.error);
            } else {
                alert(`Test deleted: "${data.deleted_test_title}"\n${data.deleted_attempts} attempts removed`);
                // Reload the dashboard
                loadDashboardBtn.click();
            }
        } catch (error) {
            console.error("Delete test error:", error);
            alert("Failed to delete test");
        }
    }

    // ---------- On load: read cookie and auto-load dashboard ----------
    const cookieDni = getCookie("quiz_dni");
    if (cookieDni) {
        dbg("Found DNI cookie, auto-loading dashboard:", cookieDni);
        dniInput.value = cookieDni;
        // Auto-trigger dashboard load
        loadDashboardBtn.click();
    } else {
        dbg("No quiz_dni cookie found on load");
    }
})();
